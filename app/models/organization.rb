class Organization < ApplicationRecord
  has_many :accesses, dependent: :restrict_with_exception
  has_many :invites, dependent: :destroy
  has_many :bank_accounts, dependent: :restrict_with_exception
  has_many :months, dependent: :restrict_with_exception

  validates :name, presence: true
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

  private

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
