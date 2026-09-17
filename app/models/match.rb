class Match < ApplicationRecord
  OBSERVATION_MAX = 2000
  LESSER = "Informe a observação do casamento"
  NO_DOCUMENTS = "Selecione ao menos um documento"
  NO_PAYMENTS = "Selecione ao menos um pagamento"
  BAD_SHAPE = "Casamento é um pagamento com um ou mais documentos, ou vários pagamentos com um documento"
  PAYMENT_TAKEN = "Pagamento já está em um casamento"
  DOCUMENT_TAKEN = "Documento já está em um casamento"

  belongs_to :month
  has_many :payments, dependent: :nullify
  has_many :supporting_documents, dependent: :nullify

  def self.confirm(month:, payments:, supporting_documents:, observation: nil)
    new(month: month).tap do |record|
      record.submit(payments: payments, supporting_documents: supporting_documents, observation: observation)
    end
  end

  def submit(payments:, supporting_documents:, observation: nil)
    errors.clear
    payments = Array(payments)
    documents = Array(supporting_documents)
    trimmed = observation.to_s.strip.presence

    if payments.empty?
      errors.add(:base, NO_PAYMENTS)
      return self
    end
    if documents.empty?
      errors.add(:base, NO_DOCUMENTS)
      return self
    end
    unless valid_shape?(payments.size, documents.size)
      errors.add(:base, BAD_SHAPE)
      return self
    end
    if trimmed && trimmed.length > OBSERVATION_MAX
      errors.add(:base, "Observação pode ter no máximo 2000 caracteres")
      return self
    end
    if documents.sum(&:amount_cents) < payments.sum(&:amount_cents) && trimmed.nil?
      errors.add(:base, LESSER)
      return self
    end

    persist_confirm(payments: payments, documents: documents, observation: trimmed)
    self
  end

  def dissolve
    transaction do
      SupportingDocument.where(match_id: id).update_all(month_id: nil, match_id: nil)
      Payment.where(match_id: id).update_all(match_id: nil)
      destroy!
    end
  end

  private

  def valid_shape?(payment_count, document_count)
    (payment_count == 1 && document_count >= 1) || (payment_count >= 2 && document_count == 1)
  end

  def persist_confirm(payments:, documents:, observation:)
    transaction do
      locked_payments = Payment.lock.where(id: payments.map(&:id)).order(:id).to_a
      locked_docs = SupportingDocument.lock.where(id: documents.map(&:id)).order(:id).to_a

      if locked_payments.any? { |payment| payment.match_id.present? }
        errors.add(:base, PAYMENT_TAKEN)
        raise ActiveRecord::Rollback
      end
      if locked_docs.any? { |document| document.match_id.present? }
        errors.add(:base, DOCUMENT_TAKEN)
        raise ActiveRecord::Rollback
      end

      self.observation = observation
      save!
      locked_payments.each do |payment|
        payment.update!(match_id: id, document_exception_kind: nil)
      end
      locked_docs.each do |document|
        document.update!(match_id: id, month_id: month_id)
      end
    end
  end
end
