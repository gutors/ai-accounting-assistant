class Month < ApplicationRecord
  YEAR_MONTH = /\A\d{4}-(0[1-9]|1[0-2])\z/
  CLOSED = "Mês fechado"
  OPEN = "Mês aberto"
  MISSING_DOCUMENT = "Há documento faltante"
  MISSING_STATEMENT = "Importe o extrato de cada conta ativa"
  MISSING_ARCHIVE = "Informe a pasta do arquivo do pacote"
  MISSING_ACCOUNTANT = "Cadastre o contador"
  WRITE_FAILED = "Não foi possível gravar no arquivo do pacote"
  INVALID = "Informe um mês válido"
  CONFIRM_NEEDS_SPREADSHEET = "Inclua o extrato planilha de pelo menos uma conta bancária."
  NOT_NEVER_SENT = "Só é possível excluir um fechamento aberto que nunca foi enviado."

  belongs_to :organization

  has_many :bank_statements, dependent: :restrict_with_exception
  has_many :matches, dependent: :destroy
  has_many :supporting_documents, dependent: :nullify

  validates :year_month, format: { with: YEAR_MONTH }
  validates :year_month, uniqueness: { scope: :organization_id }

  def self.open(organization:, year_month:)
    year_month = year_month.to_s.strip
    unless valid_year_month?(year_month)
      record = organization.months.new(year_month: year_month)
      record.errors.add(:base, INVALID)
      return record
    end

    existing = organization.months.find_by(year_month: year_month)
    return existing if existing

    record = organization.months.new(year_month: year_month)
    record.save
    record
  rescue ActiveRecord::RecordNotUnique
    organization.months.find_by!(year_month: year_month)
  end

  def self.valid_year_month?(value)
    value.to_s.match?(YEAR_MONTH)
  end

  def close_for_send(writer: PackageArchiveWriter.current, supporting_documents: [])
    errors.clear
    with_lock do
      if (message = close_blocker)
        errors.add(:base, message)
        next
      end

      persist_closed_package(writer, supporting_documents: Array(supporting_documents))
    end
    self
  end

  def restore_month_folder(writer: PackageArchiveWriter.current)
    errors.clear
    with_lock do
      unless closed?
        errors.add(:base, OPEN)
        next
      end

      writer.replace_month_folder(
        parent_id: organization.package_archive_folder_id,
        name: year_month,
        folder_id: month_folder_id,
        files: MonthPackage.files(self)
      )
    rescue PackageArchiveWriter::Error
      errors.add(:base, WRITE_FAILED)
    end
    self
  end

  def reopen
    errors.clear
    with_lock do
      unless closed?
        errors.add(:base, OPEN)
        next
      end

      update!(closed: false)
    end
    self
  end

  def confirm_accounts
    errors.clear
    with_lock do
      if closed?
        errors.add(:base, CLOSED)
        next
      end
      unless spreadsheet_present?
        errors.add(:base, CONFIRM_NEEDS_SPREADSHEET)
        next
      end

      update!(accounts_confirmed: true)
    end
    self
  end

  def discard_never_sent
    errors.clear
    with_lock do
      unless never_sent?
        errors.add(:base, NOT_NEVER_SENT)
        next
      end

      bank_statements.find_each(&:destroy!)
      destroy!
    end
    self
  end

  def spreadsheet_present?
    bank_statements.joins(:spreadsheet_attachment).exists?
  end

  def never_sent?
    !closed? && month_folder_id.blank?
  end

  private

  def close_blocker
    return CLOSED if closed?
    return MISSING_DOCUMENT if Payment.for_month(self).missing_document.exists?
    return MISSING_STATEMENT if missing_active_statement?
    return MISSING_ARCHIVE if organization.package_archive_folder_id.blank?
    return MISSING_ACCOUNTANT if organization.accountant_presentation_name.blank?

    nil
  end

  def missing_active_statement?
    active_ids = organization.bank_accounts.where(active: true).pluck(:id)
    present_ids = bank_statements.where(bank_account_id: active_ids).pluck(:bank_account_id)
    (active_ids - present_ids).any?
  end

  def persist_closed_package(writer, supporting_documents:)
    selected = lock_unmatched_selection(supporting_documents)
    return if errors.any?

    files = MonthPackage.files(self, extra_unmatched: selected)
    folder_id = writer.replace_month_folder(
      parent_id: organization.package_archive_folder_id,
      name: year_month,
      folder_id: month_folder_id,
      files: files
    )
    selected.each { |document| document.update!(month_id: id) }
    update!(closed: true, month_folder_id: folder_id)
  rescue PackageArchiveWriter::Error
    errors.add(:base, WRITE_FAILED)
  end

  def lock_unmatched_selection(documents)
    return [] if documents.empty?

    locked = SupportingDocument.lock.where(id: documents.map(&:id)).order(:id).to_a
    if locked.any? { |document| document.match_id.present? }
      errors.add(:base, Match::DOCUMENT_TAKEN)
      return []
    end
    if locked.any? { |document| document.month_id.present? }
      errors.add(:base, SupportingDocument::HAS_MONTH)
      return []
    end

    locked
  end
end
