require "base64"
require "openssl"

class Organization < ApplicationRecord
  MAX_SEFAZ_PKCS12_BYTES = 1_048_576
  SEFAZ_OPEN_FAILED = "Não foi possível abrir o certificado com essa senha"
  SEFAZ_NOT_ECNPJ = "O certificado deve ser e-CNPJ A1 vigente"
  SEFAZ_WRAP_FAILED = "O certificado não pôde ser guardado"

  belongs_to :principal_coordinator_account, class_name: "Account"

  has_many :accesses, dependent: :restrict_with_exception
  has_many :invites, dependent: :destroy
  has_many :bank_accounts, dependent: :restrict_with_exception
  has_many :months, dependent: :restrict_with_exception
  has_many :supporting_documents, dependent: :restrict_with_exception
  has_many :justifications, dependent: :restrict_with_exception
  has_many :extra_exception_kinds, dependent: :restrict_with_exception

  validates :name, presence: true

  def self.register_coordinator(name:, email:)
    transaction do
      normalized = NormalizedEmail.normalize(email)
      account = Account.find_by(email: normalized)
      unless account
        begin
          account = Account.create!(email: normalized)
        rescue ActiveRecord::RecordNotUnique
          account = Account.find_by!(email: normalized)
        end
      end
      organization = create!(name: name.to_s.strip, principal_coordinator_account: account)
      Access.create!(account: account, organization: organization, kind: :coordinator)
      organization
    end
  end

  def self.name_taken?(name, except: nil)
    stripped = name.to_s.strip
    return false if stripped.blank?

    scope = where("lower((name)::text) = ?", stripped.downcase)
    scope = scope.where.not(id: except.id) if except
    scope.exists?
  end

  def coordinator_emails
    listed_coordinator_accounts.map(&:email)
  end

  def listed_coordinator_account
    principal_coordinator_account
  end

  def listed_coordinator_signed_in?
    listed_coordinator_account&.google_uid.present?
  end

  def listed_coordinator_accounts
    coordinators = accesses.coordinator.includes(:account).map(&:account)
    principal = principal_coordinator_account
    rest = coordinators.reject { |account| account.id == principal&.id }.sort_by(&:email)
    [ principal ].compact + rest
  end

  def home_coordinator_accesses
    records = accesses.coordinator.includes(:account).to_a
    principal, others = records.partition { |access| access.account_id == principal_coordinator_account_id }
    principal + others.sort_by { |access| access.account.email }
  end

  PrincipalReplacement = Data.define(:account, :created_account)

  def replace_coordinator(access:, email:)
    normalized = NormalizedEmail.normalize(email)
    return PrincipalReplacement.new(account: access.account, created_account: false) if access.account.email == normalized

    created_account = false
    account = nil
    transaction do
      account = Account.find_by(email: normalized)
      unless account
        account = Account.create!(email: normalized)
        created_account = true
      end
      standing = accesses.find_by(account_id: account.id)
      if standing
        standing.update!(kind: :coordinator) unless standing.coordinator?
      else
        Access.create!(account: account, organization: self, kind: :coordinator)
      end
      invites.where(email: normalized).delete_all
      update!(principal_coordinator_account: account)
      access.destroy! if access.account_id != account.id
    end
    PrincipalReplacement.new(account: account, created_account: created_account)
  end

  def remove
    if bank_accounts.exists? || months.exists? || supporting_documents.exists? ||
        justifications.exists? || extra_exception_kinds.exists?
      errors.add(:base, "Esta organização já tem dados de fechamento e não pode ser removida.")
      return false
    end

    transaction do
      Access.where(organization_id: id).delete_all
      Invite.where(organization_id: id).delete_all
      destroy!
    end
    true
  end

  validate :accountant_shape, on: :accountant

  def update_accountant(params)
    self.accountant_presentation_name = params[:presentation_name].to_s.strip.presence
    self.accountant_tax_id = BrazilianTaxId.normalize(params[:tax_id])
    self.accountant_legal_name = params[:legal_name].to_s.strip.presence
    self.accountant_pix_key = params[:pix_key].to_s.strip.presence
    self.package_destination_email = NormalizedEmail.normalize(params[:destination_email])
    save(context: :accountant)
  end

  def update_package_archive(url)
    parsed = DriveFolderUrl.parse(url)
    unless parsed.ok?
      errors.add(:package_archive_url, :invalid)
      return false
    end

    update(package_archive_url: parsed.url, package_archive_folder_id: parsed.folder_id)
  end

  def install_sefaz_certificate(file:, passphrase:)
    errors.clear
    bytes, filename = read_sefaz_upload(file)
    unless bytes
      errors.add(:base, SEFAZ_NOT_ECNPJ)
      return false
    end
    if bytes.bytesize > MAX_SEFAZ_PKCS12_BYTES
      errors.add(:base, SEFAZ_NOT_ECNPJ)
      return false
    end
    unless %w[.pfx .p12].include?(File.extname(filename).downcase)
      errors.add(:base, SEFAZ_NOT_ECNPJ)
      return false
    end

    begin
      pkcs12 = OpenSSL::PKCS12.new(bytes, passphrase.to_s)
    rescue OpenSSL::PKCS12::PKCS12Error
      errors.add(:base, SEFAZ_OPEN_FAILED)
      return false
    end

    cert = pkcs12.certificate
    titular = titular_from_certificate(cert)
    not_after = cert.not_after.utc.to_date
    unless titular&.length == 14 && not_after >= Date.current
      errors.add(:base, SEFAZ_NOT_ECNPJ)
      return false
    end

    unless WrapKey.present?
      errors.add(:base, SEFAZ_WRAP_FAILED)
      return false
    end

    persist_sefaz_slot(bytes:, passphrase: passphrase.to_s, titular:, not_after:)
  rescue WrapKey::Missing
    errors.add(:base, SEFAZ_WRAP_FAILED)
    false
  end

  def remove_sefaz_certificate
    update!(
      sefaz_pkcs12_ciphertext: nil,
      sefaz_passphrase_ciphertext: nil,
      sefaz_titular_cnpj: nil,
      sefaz_not_after: nil
    )
  end

  def sefaz_certificate_expired?
    sefaz_not_after.present? && sefaz_not_after < Date.current
  end

  def sefaz_titular_display
    digits = sefaz_titular_cnpj.to_s
    return if digits.length != 14

    "#{digits[0, 2]}.#{digits[2, 3]}.#{digits[5, 3]}/#{digits[8, 4]}-#{digits[12, 2]}"
  end

  def unwrap_sefaz_pkcs12
    return if sefaz_pkcs12_ciphertext.blank? || sefaz_passphrase_ciphertext.blank?

    bytes = Base64.strict_decode64(WrapKey.decrypt(sefaz_pkcs12_ciphertext))
    OpenSSL::PKCS12.new(bytes, WrapKey.decrypt(sefaz_passphrase_ciphertext))
  end

  private

  def persist_sefaz_slot(bytes:, passphrase:, titular:, not_after:)
    transaction do
      lock!
      self.sefaz_pkcs12_ciphertext = WrapKey.encrypt(Base64.strict_encode64(bytes))
      self.sefaz_passphrase_ciphertext = WrapKey.encrypt(passphrase)
      self.sefaz_titular_cnpj = titular
      self.sefaz_not_after = not_after
      save!
    end
    true
  end

  def read_sefaz_upload(file)
    return unless file.respond_to?(:original_filename)

    filename = file.original_filename.to_s
    return if filename.blank?

    size = file.size if file.respond_to?(:size)
    return [ "x" * (MAX_SEFAZ_PKCS12_BYTES + 1), filename ] if size && size > MAX_SEFAZ_PKCS12_BYTES

    file.rewind if file.respond_to?(:rewind)
    bytes = file.read
    file.rewind if file.respond_to?(:rewind)
    [ bytes, filename ]
  end

  def titular_from_certificate(certificate)
    haystack = certificate.subject.to_s
    haystack.scan(/\d{14}/).first || haystack.scan(/\d{11}/).first
  end

  def accountant_shape
    satellites_present = accountant_tax_id.present? || accountant_legal_name.present? ||
      accountant_pix_key.present? || package_destination_email.present?

    if satellites_present && accountant_presentation_name.blank?
      errors.add(:accountant_presentation_name, :blank)
      return
    end

    return if accountant_presentation_name.blank?

    if accountant_pix_key.present? && accountant_pix_key.length > 77
      errors.add(:accountant_pix_key, :invalid)
    end

    if package_destination_email.present? && !NormalizedEmail.valid?(package_destination_email)
      errors.add(:package_destination_email, :invalid)
    end

    if accountant_tax_id.present?
      unless BrazilianTaxId.valid?(accountant_tax_id)
        errors.add(:accountant_tax_id, :invalid)
        return
      end

      if BrazilianTaxId.cnpj?(accountant_tax_id) && accountant_legal_name.blank?
        errors.add(:accountant_legal_name, :blank)
      end

      if BrazilianTaxId.cpf?(accountant_tax_id) && accountant_legal_name.present?
        errors.add(:accountant_legal_name, :present)
      end
    elsif accountant_legal_name.present?
      errors.add(:accountant_legal_name, :invalid)
    end
  end
end
