class SupportingDocument < ApplicationRecord
  MAX_BYTES = 10_485_760
  PHOTO_EXT = %w[.jpg .jpeg .png .webp .pdf].freeze
  PAYEE_MAX = 200
  OBSERVATION_MAX = 2000
  RECIBO_PHOTO = "Envie a foto do recibo"
  RECIBO_XML = "Recibo não tem XML"
  NF_FILES = "Envie a foto e/ou o XML"
  MISSING_FIELDS = "Informe valor, data e favorecido"
    BAD_KIND = "Informe se é nota fiscal ou recibo"
  PHOTO_LOCKED = "A foto não pode ser alterada. Exclua o documento e inclua novamente."
  XML_LOCKED = "O XML não pode ser alterado. Exclua o documento e inclua novamente."
  KIND_LOCKED = "O tipo não pode ser alterado. Exclua o documento e inclua novamente."
  OVERSIZE = "Cada arquivo pode ter no máximo 10 MB"
  PHOTO_TYPE = "A foto deve ser JPEG, PNG, WebP ou PDF"
  XML_TYPE = "O XML deve ser um arquivo .xml"
  PAYEE_LENGTH = "Favorecido pode ter no máximo 200 caracteres"
  HAS_MONTH = "Documento já pertence a um mês"
  XML_UNREADABLE = "O XML da nota fiscal não pôde ser lido"
  LOCKED_FIELDS = "Valor, data e favorecido vêm da nota e não podem ser alterados"
  CHAVE_DIGITS = "Informe a chave de acesso com 44 dígitos"
  SEFAZ_CONFIRM_FAILED = "Não foi possível consultar a SEFAZ"
  ORIGIN_TYPED = "typed"
  ORIGIN_UPLOADED_XML = "uploaded_xml"
  ORIGIN_IDENTIFIED = "identified"
  ORIGIN_PHOTO = "photo"
  ORIGIN_NFC_E_PUBLIC = "nfc_e_public"

  belongs_to :organization
  belongs_to :account
  belongs_to :match, optional: true
  belongs_to :month, optional: true
  belongs_to :justification, optional: true
  has_one_attached :photo
  has_one_attached :xml

  enum :kind, { nota_fiscal: "nota_fiscal", recibo: "recibo" }, validate: true

  scope :listed, -> { with_attached_photo.with_attached_xml.order(document_on: :desc, id: :desc) }
  scope :unmatched, -> { where(match_id: nil) }

  def self.insert(organization:, account:, kind:, amount:, date:, payee:, observation: nil, photo: nil, xml: nil, chave: nil)
    new(organization: organization, account: account).tap do |doc|
      doc.submit(kind: kind, amount: amount, date: date, payee: payee, observation: observation, photo: photo, xml: xml, chave: chave)
    end
  end

  def apply(**attrs)
    submit(**attrs)
    self
  end

  def withdraw
    errors.clear
    withdrawn = false
    transaction do
      lock!
      if month_id.present?
        errors.add(:base, HAS_MONTH)
        raise ActiveRecord::Rollback
      end

      grouping_id = justification_id
      photo.purge if photo.attached?
      xml.purge if xml.attached?
      destroy!
      if grouping_id
        grouping = Justification.find(grouping_id)
        grouping.destroy! unless grouping.supporting_documents.exists?
      end
      withdrawn = true
    end
    withdrawn
  end

  def return_to_no_month
    errors.clear
    transaction do
      locked_month = Month.lock.find_by(id: month_id)
      lock!
      if locked_month&.closed?
        errors.add(:base, Month::CLOSED)
        raise ActiveRecord::Rollback
      end

      update!(month_id: nil)
    end
    self
  end

  def submit(**attrs)
    errors.clear
    if month&.closed?
      errors.add(:base, Month::CLOSED)
      return self
    end

    attrs = attrs.symbolize_keys

    next_kind = attrs.key?(:kind) ? attrs[:kind].to_s : kind.to_s
    unless %w[nota_fiscal recibo].include?(next_kind)
      errors.add(:base, BAD_KIND)
      return self
    end
    if persisted? && attrs.key?(:kind) && next_kind != kind.to_s
      errors.add(:base, KIND_LOCKED)
      return self
    end

    incoming_photo = uploaded?(attrs[:photo]) ? attrs[:photo] : nil
    incoming_xml = uploaded?(attrs[:xml]) ? attrs[:xml] : nil

    if incoming_photo
      if oversized?(incoming_photo)
        errors.add(:base, OVERSIZE)
        return self
      end
      unless photo_ext?(incoming_photo)
        errors.add(:base, PHOTO_TYPE)
        return self
      end
    end
    if incoming_xml
      if oversized?(incoming_xml)
        errors.add(:base, OVERSIZE)
        return self
      end
      unless xml_ext?(incoming_xml)
        errors.add(:base, XML_TYPE)
        return self
      end
    end

    if persisted? && incoming_photo && photo.attached?
      errors.add(:base, PHOTO_LOCKED)
      return self
    end
    if persisted? && incoming_xml && xml.attached?
      errors.add(:base, XML_LOCKED)
      return self
    end

    if next_kind == "recibo" && incoming_xml
      errors.add(:base, RECIBO_XML)
      return self
    end

    parsed_nfe = nil
    if next_kind == "nota_fiscal" && incoming_xml
      parsed_nfe = AuthorizedNfe.parse(read_bytes(incoming_xml))
      unless parsed_nfe
        errors.add(:base, XML_UNREADABLE)
        return self
      end
    end

    next_chave = nil
    identified_xml = nil
    identified_resumo = nil
    public_fields = nil
    photo_fields = nil
    confirm_pending = sefaz_confirm_pending
    photo_symbols = PhotoSymbols::Symbols.new(chave: nil, qr_url: nil)
    extract_source = photo_source_for_extract(incoming_photo, next_kind) if parsed_nfe.nil? && next_kind == "nota_fiscal"
    ocr_text = nil
    ocr_computed = false
    lazy_ocr = lambda {
      unless ocr_computed
        ocr_text = PhotoOcr.text(extract_source[:bytes])
        ocr_computed = true
      end
      ocr_text
    }
    if extract_source
      photo_symbols = PhotoSymbols.current.scan(
        bytes: extract_source[:bytes],
        filename: extract_source[:filename],
        text: lazy_ocr
      )
    end

    if next_kind == "nota_fiscal"
      photo_chave = forty_four_digits(photo_symbols.chave)
      typed_chave = nil
      if attrs.key?(:chave) && attrs[:chave].to_s.strip.present?
        digits = attrs[:chave].to_s.gsub(/\D/, "")
        if digits.length == 44
          typed_chave = digits
        elsif photo_chave.nil?
          errors.add(:base, CHAVE_DIGITS)
          return self
        end
      end
      next_chave = if parsed_nfe
        parsed_nfe.chave
      else
        photo_chave || typed_chave || chave
      end

      should_consult = parsed_nfe.nil? && next_chave.present? && !fields_locked? && (
        !persisted? || attrs.key?(:chave) || kind != "nota_fiscal"
      )
      awaiting_confirm = persisted? && kind == "nota_fiscal" && attrs.key?(:chave) && !fields_locked?
      confirm_pending = false if awaiting_confirm

      if should_consult
        case consult_identified(next_chave)
        in SefazConsulta::Xml => consulta_xml
          if awaiting_confirm
            confirm_pending = true
          else
            parsed_nfe = AuthorizedNfe.parse(consulta_xml.bytes)
            identified_xml = consulta_xml.bytes if parsed_nfe
          end
        in SefazConsulta::Resumo => resumo
          if awaiting_confirm
            confirm_pending = true
          else
            identified_resumo = resumo
          end
        else
          nil
        end
      end

      identified_delivered = parsed_nfe.present? || identified_resumo.present?
      if !identified_delivered && photo_symbols.qr_url.present?
        case PublicNfceConsulta.current.fetch(photo_symbols.qr_url)
        in PublicNfceConsulta::Fields => fields if complete_triple?(fields.amount_cents, fields.document_on, fields.payee)
          public_fields = fields
        in PublicNfceConsulta::Error
          nil
        else
          nil
        end
      end
      if !identified_delivered && public_fields.nil? && extract_source
        case PhotoFields.current.read(
          bytes: extract_source[:bytes],
          filename: extract_source[:filename],
          text: lazy_ocr
        )
        in PhotoFields::Fields => fields if complete_triple?(fields.amount_cents, fields.document_on, fields.payee)
          photo_fields = fields
        else
          nil
        end
      end
    end

    next_cents = if parsed_nfe
      parsed_nfe.amount_cents
    elsif identified_resumo
      identified_resumo.amount_cents
    elsif public_fields
      public_fields.amount_cents
    elsif photo_fields
      photo_fields.amount_cents
    elsif attrs.key?(:amount)
      BrlCents.parse(attrs[:amount])
    else
      amount_cents
    end
    next_on = if parsed_nfe
      parsed_nfe.document_on
    elsif identified_resumo
      identified_resumo.document_on
    elsif public_fields
      public_fields.document_on
    elsif photo_fields
      photo_fields.document_on
    elsif attrs.key?(:date)
      parse_document_on(attrs[:date])
    else
      document_on
    end
    next_payee = if parsed_nfe
      parsed_nfe.payee
    elsif identified_resumo
      identified_resumo.payee
    elsif public_fields
      public_fields.payee
    elsif photo_fields
      photo_fields.payee
    elsif attrs.key?(:payee)
      attrs[:payee].to_s.strip
    else
      payee
    end

    if fields_locked? && next_kind != "recibo" && parsed_nfe.nil?
      amount_changing = attrs.key?(:amount) && next_cents != amount_cents
      date_changing = attrs.key?(:date) && next_on != document_on
      payee_changing = attrs.key?(:payee) && next_payee != payee
      if amount_changing || date_changing || payee_changing
        errors.add(:base, LOCKED_FIELDS)
        return self
      end
    end

    if next_cents.nil? || next_cents == 0 || next_on.nil? || next_payee.blank?
      errors.add(:base, MISSING_FIELDS)
      return self
    end
    if next_payee.length > PAYEE_MAX
      errors.add(:base, PAYEE_LENGTH)
      return self
    end

    next_observation = if attrs.key?(:observation)
      attrs[:observation].to_s.strip.presence
    else
      observation
    end
    if next_observation && next_observation.length > OBSERVATION_MAX
      errors.add(:base, "Observação pode ter no máximo 2000 caracteres")
      return self
    end

    will_have_photo = incoming_photo.present? || (persisted? && photo.attached?)
    will_have_xml = incoming_xml.present? || identified_xml.present? || (persisted? && xml.attached?)
    if next_kind == "recibo"
      unless will_have_photo
        errors.add(:base, RECIBO_PHOTO)
        return self
      end
    elsif !will_have_photo && !will_have_xml
      errors.add(:base, NF_FILES)
      return self
    end

    next_origin = if next_kind == "recibo"
      ORIGIN_TYPED
    elsif incoming_xml && parsed_nfe
      ORIGIN_UPLOADED_XML
    elsif identified_xml || identified_resumo
      ORIGIN_IDENTIFIED
    elsif public_fields
      ORIGIN_NFC_E_PUBLIC
    elsif photo_fields
      ORIGIN_PHOTO
    else
      fields_origin.presence || ORIGIN_TYPED
    end
    next_chave = nil if next_kind == "recibo"
    confirm_pending = false if next_kind == "recibo"

    persist_document(
      kind: next_kind,
      amount_cents: next_cents,
      document_on: next_on,
      payee: next_payee,
      observation: next_observation,
      photo: incoming_photo,
      xml: incoming_xml,
      chave: next_chave,
      fields_origin: next_origin,
      identified_xml: identified_xml,
      sefaz_confirm_pending: confirm_pending
    )
    self
  end

  def fields_locked?
    [ ORIGIN_UPLOADED_XML, ORIGIN_IDENTIFIED ].include?(fields_origin)
  end

  def confirm_identified_sefaz
    errors.clear
    if month&.closed?
      errors.add(:base, Month::CLOSED)
      return false
    end
    return true if fields_origin == ORIGIN_IDENTIFIED
    if fields_origin == ORIGIN_UPLOADED_XML
      errors.add(:base, LOCKED_FIELDS)
      return false
    end
    return fail_confirm if chave.blank?

    case consult_identified(chave)
    in SefazConsulta::Xml => consulta_xml
      parsed = AuthorizedNfe.parse(consulta_xml.bytes)
      return fail_confirm unless parsed

      persist_document(
        kind: "nota_fiscal",
        amount_cents: parsed.amount_cents,
        document_on: parsed.document_on,
        payee: parsed.payee,
        observation: observation,
        photo: nil,
        xml: nil,
        chave: parsed.chave,
        fields_origin: ORIGIN_IDENTIFIED,
        identified_xml: consulta_xml.bytes,
        sefaz_confirm_pending: false
      )
      true
    in SefazConsulta::Resumo => resumo
      persist_document(
        kind: "nota_fiscal",
        amount_cents: resumo.amount_cents,
        document_on: resumo.document_on,
        payee: resumo.payee,
        observation: observation,
        photo: nil,
        xml: nil,
        chave: chave,
        fields_origin: ORIGIN_IDENTIFIED,
        sefaz_confirm_pending: false
      )
      true
    else
      fail_confirm
    end
  end

  private

  def persist_document(kind:, amount_cents:, document_on:, payee:, observation:, photo:, xml:, chave:, fields_origin:, identified_xml: nil, sefaz_confirm_pending: false)
    transaction do
      self.kind = kind
      self.amount_cents = amount_cents
      self.document_on = document_on
      self.payee = payee
      self.observation = observation
      self.chave = chave
      self.fields_origin = fields_origin
      self.sefaz_confirm_pending = sefaz_confirm_pending
      save!
      self.photo.attach(photo) if photo
      self.xml.attach(xml) if xml
      if identified_xml
        self.xml.attach(
          io: StringIO.new(identified_xml),
          filename: "#{chave}.xml",
          content_type: "application/xml"
        )
      end
      self.xml.purge if recibo? && self.xml.attached?
    end
  end

  def fail_confirm
    errors.add(:base, SEFAZ_CONFIRM_FAILED)
    false
  end

  def consult_identified(chave_digits)
    pkcs12 = organization.sefaz_pkcs12
    return unless pkcs12

    SefazConsulta.current.lookup(pkcs12:, chave: chave_digits)
  rescue Timeout::Error, OpenSSL::PKCS12::PKCS12Error, WrapKey::Missing
    SefazConsulta::Error.new
  end

  def read_bytes(file)
    if file.respond_to?(:rewind)
      file.rewind
      data = file.read
      file.rewind
      data
    else
      File.binread(file.path)
    end
  end

  def uploaded?(file)
    file.present? && filename_of(file).present?
  end

  def filename_of(file)
    if file.respond_to?(:original_filename)
      file.original_filename.to_s
    elsif file.respond_to?(:filename)
      file.filename.to_s
    else
      File.basename(file.path)
    end
  end

  def photo_ext?(file)
    PHOTO_EXT.include?(File.extname(filename_of(file)).downcase)
  end

  def xml_ext?(file)
    File.extname(filename_of(file)).downcase == ".xml"
  end

  def oversized?(file)
    size = if file.respond_to?(:size) && file.size
      file.size
    else
      bytes = if file.respond_to?(:rewind)
        file.rewind
        data = file.read
        file.rewind
        data
      else
        File.binread(file.path)
      end
      bytes.bytesize
    end
    size > MAX_BYTES
  end

  def photo_source_for_extract(incoming_photo, next_kind)
    if !persisted? && incoming_photo
      { bytes: read_bytes(incoming_photo), filename: filename_of(incoming_photo) }
    elsif persisted? && kind.to_s == "recibo" && next_kind == "nota_fiscal"
      if incoming_photo
        { bytes: read_bytes(incoming_photo), filename: filename_of(incoming_photo) }
      elsif photo.attached?
        { bytes: photo.download, filename: photo.filename.to_s }
      end
    end
  end

  def forty_four_digits(value)
    digits = value.to_s.gsub(/\D/, "")
    digits if digits.length == 44
  end

  def complete_triple?(amount_cents, document_on, payee)
    amount_cents.is_a?(Integer) && amount_cents.positive? && document_on.present? && payee.present?
  end

  def parse_document_on(value)
    return value if value.is_a?(Date)

    Date.iso8601(value.to_s)
  rescue ArgumentError, Date::Error
    nil
  end
end
