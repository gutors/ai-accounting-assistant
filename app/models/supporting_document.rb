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
  OVERSIZE = "Cada arquivo pode ter no máximo 10 MB"
  PHOTO_TYPE = "A foto deve ser JPEG, PNG, WebP ou PDF"
  XML_TYPE = "O XML deve ser um arquivo .xml"
  PAYEE_LENGTH = "Favorecido pode ter no máximo 200 caracteres"
  HAS_MONTH = "Documento já pertence a um mês"
  XML_UNREADABLE = "O XML da nota fiscal não pôde ser lido"
  LOCKED_FIELDS = "Valor, data e favorecido vêm da nota e não podem ser alterados"
  CHAVE_DIGITS = "Informe a chave de acesso com 44 dígitos"
  ORIGIN_TYPED = "typed"
  ORIGIN_UPLOADED_XML = "uploaded_xml"
  ORIGIN_IDENTIFIED = "identified"

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
    if next_kind == "nota_fiscal"
      if attrs.key?(:chave) && attrs[:chave].to_s.strip.present?
        digits = attrs[:chave].to_s.gsub(/\D/, "")
        unless digits.length == 44
          errors.add(:base, CHAVE_DIGITS)
          return self
        end
        next_chave = digits
      elsif parsed_nfe
        next_chave = parsed_nfe.chave
      else
        next_chave = chave
      end

      if parsed_nfe.nil? && next_chave.present? && !persisted?
        case consult_identified(next_chave)
        in SefazConsulta::Xml => consulta_xml
          parsed_nfe = AuthorizedNfe.parse(consulta_xml.bytes)
          identified_xml = consulta_xml.bytes if parsed_nfe
        in SefazConsulta::Resumo => resumo
          identified_resumo = resumo
        else
          nil
        end
      end
    end

    next_cents = if parsed_nfe
      parsed_nfe.amount_cents
    elsif identified_resumo
      identified_resumo.amount_cents
    elsif attrs.key?(:amount)
      BrlCents.parse(attrs[:amount])
    else
      amount_cents
    end
    next_on = if parsed_nfe
      parsed_nfe.document_on
    elsif identified_resumo
      identified_resumo.document_on
    elsif attrs.key?(:date)
      parse_document_on(attrs[:date])
    else
      document_on
    end
    next_payee = if parsed_nfe
      parsed_nfe.payee
    elsif identified_resumo
      identified_resumo.payee
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
    else
      fields_origin.presence || ORIGIN_TYPED
    end
    next_chave = nil if next_kind == "recibo"

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
      identified_xml: identified_xml
    )
    self
  end

  def fields_locked?
    [ ORIGIN_UPLOADED_XML, ORIGIN_IDENTIFIED ].include?(fields_origin)
  end

  private

  def persist_document(kind:, amount_cents:, document_on:, payee:, observation:, photo:, xml:, chave:, fields_origin:, identified_xml: nil)
    transaction do
      self.kind = kind
      self.amount_cents = amount_cents
      self.document_on = document_on
      self.payee = payee
      self.observation = observation
      self.chave = chave
      self.fields_origin = fields_origin
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

  def consult_identified(chave_digits)
    org = organization
    return if org.sefaz_titular_cnpj.blank?
    return if org.sefaz_certificate_expired?
    return unless WrapKey.present?

    pkcs12 = org.unwrap_sefaz_pkcs12
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

  def parse_document_on(value)
    return value if value.is_a?(Date)

    Date.iso8601(value.to_s)
  rescue ArgumentError, Date::Error
    nil
  end
end
