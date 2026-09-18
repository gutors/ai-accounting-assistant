class Justification < ApplicationRecord
  INVALID_AMOUNT = "Informe o valor gasto"
  MISSING_DOCUMENTS = "Selecione ao menos um documento"
  INELIGIBLE_DOCUMENT = "Documento não pode entrar nesta justificativa"
  MEMBER_HAS_MONTH = "Documento já pertence a um mês"

  belongs_to :organization
  belongs_to :account
  has_many :supporting_documents

  def self.declare(organization:, account:, amount:, supporting_document_ids:)
    new(organization: organization, account: account).tap do |justification|
      justification.cover(amount: amount, supporting_document_ids: supporting_document_ids)
    end
  end

  def cover(amount:, supporting_document_ids:)
    errors.clear
    cents = BrlCents.parse(amount)
    if cents.nil? || cents == 0
      errors.add(:base, INVALID_AMOUNT)
      return self
    end

    ids = Array(supporting_document_ids).map(&:to_i).reject(&:zero?).uniq
    if ids.empty?
      errors.add(:base, MISSING_DOCUMENTS)
      return self
    end

    transaction do
      documents = SupportingDocument.where(id: ids, organization_id: organization_id).order(:id).lock.to_a
      unless documents.size == ids.size && documents.all? { |document| eligible?(document) }
        errors.add(:base, INELIGIBLE_DOCUMENT)
        raise ActiveRecord::Rollback
      end

      self.amount_cents = cents
      save!
      documents.each { |document| document.update!(justification: self) }
    end
    self
  end

  def replace_amount(amount)
    errors.clear
    cents = BrlCents.parse(amount)
    if cents.nil? || cents == 0
      errors.add(:base, INVALID_AMOUNT)
      return false
    end
    if supporting_documents.where.not(month_id: nil).exists?
      errors.add(:base, MEMBER_HAS_MONTH)
      return false
    end

    update!(amount_cents: cents)
    true
  end

  private

  def eligible?(document)
    document.account_id == account_id &&
      document.month_id.nil? &&
      document.justification_id.nil?
  end
end
