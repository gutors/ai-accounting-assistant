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

  belongs_to :organization
  belongs_to :account
  belongs_to :match, optional: true
  belongs_to :month, optional: true
  has_one_attached :photo
  has_one_attached :xml

  enum :kind, { nota_fiscal: "nota_fiscal", recibo: "recibo" }, validate: true

  scope :listed, -> { with_attached_photo.with_attached_xml.order(document_on: :desc, id: :desc) }
  scope :unmatched, -> { where(match_id: nil) }

  def self.insert(organization:, account:, kind:, amount:, date:, payee:, observation: nil, photo: nil, xml: nil)
    new(organization: organization, account: account).tap do |doc|
      doc.submit(kind: kind, amount: amount, date: date, payee: payee, observation: observation, photo: photo, xml: xml)
    end
  end

  def apply(**attrs)
    submit(**attrs)
    self
  end

  def withdraw
    errors.clear
    if month_id.present?
      errors.add(:base, HAS_MONTH)
      return false
    end

    transaction do
      photo.purge if photo.attached?
      xml.purge if xml.attached?
      destroy!
    end
    true
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

    next_cents = attrs.key?(:amount) ? BrlCents.parse(attrs[:amount]) : amount_cents
    next_on = attrs.key?(:date) ? parse_document_on(attrs[:date]) : document_on
    next_payee = attrs.key?(:payee) ? attrs[:payee].to_s.strip : payee
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

    will_have_photo = incoming_photo.present? || (persisted? && photo.attached?)
    will_have_xml = incoming_xml.present? || (persisted? && xml.attached?)
    if next_kind == "recibo"
      unless will_have_photo
        errors.add(:base, RECIBO_PHOTO)
        return self
      end
    elsif !will_have_photo && !will_have_xml
      errors.add(:base, NF_FILES)
      return self
    end

    persist_document(
      kind: next_kind,
      amount_cents: next_cents,
      document_on: next_on,
      payee: next_payee,
      observation: next_observation,
      photo: incoming_photo,
      xml: incoming_xml
    )
    self
  end

  private

  def persist_document(kind:, amount_cents:, document_on:, payee:, observation:, photo:, xml:)
    transaction do
      self.kind = kind
      self.amount_cents = amount_cents
      self.document_on = document_on
      self.payee = payee
      self.observation = observation
      save!
      self.photo.attach(photo) if photo
      self.xml.attach(xml) if xml
      self.xml.purge if recibo? && self.xml.attached?
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
