class Payment < ApplicationRecord
  UNKNOWN_KIND = "Informe se é tarifa bancária ou honorário do contador"
  MATCHED = "Desfaça o casamento antes de marcar a exceção"

  belongs_to :bank_statement
  belongs_to :match, optional: true

  enum :document_exception_kind, { bank_fee: "bank_fee", accountant_fee: "accountant_fee" }, validate: { allow_nil: true }

  scope :for_month, ->(month) { joins(:bank_statement).where(bank_statements: { month_id: month.id }) }
  scope :missing_document, -> { where(match_id: nil, document_exception_kind: nil) }

  before_destroy :dissolve_own_match

  def missing_document?
    match_id.nil? && document_exception_kind.nil?
  end

  def mark_document_exception(kind)
    errors.clear
    if bank_statement.month.closed?
      errors.add(:base, Month::CLOSED)
      return self
    end

    value = kind.to_s
    unless %w[bank_fee accountant_fee].include?(value)
      errors.add(:base, UNKNOWN_KIND)
      return self
    end
    if match_id.present?
      errors.add(:base, MATCHED)
      return self
    end

    update!(document_exception_kind: value)
    self
  end

  def unmark_document_exception
    errors.clear
    if bank_statement.month.closed?
      errors.add(:base, Month::CLOSED)
      return self
    end

    update!(document_exception_kind: nil)
    self
  end

  private

  def dissolve_own_match
    return if match_id.nil?

    Match.find_by(id: match_id)&.dissolve
  end
end
