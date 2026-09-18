class Payment < ApplicationRecord
  UNKNOWN_KIND = "Informe um tipo de exceção permitido"
  MATCHED = "Desfaça o casamento antes de marcar a exceção"

  belongs_to :bank_statement
  belongs_to :match, optional: true
  belongs_to :extra_exception_kind, optional: true

  enum :document_exception_kind, { bank_fee: "bank_fee", accountant_fee: "accountant_fee" }, validate: { allow_nil: true }

  scope :for_month, ->(month) { joins(:bank_statement).where(bank_statements: { month_id: month.id }) }
  scope :missing_document, -> { where(match_id: nil, document_exception_kind: nil, extra_exception_kind_id: nil) }

  before_destroy :dissolve_own_match

  def missing_document?
    match_id.nil? && document_exception_kind.nil? && extra_exception_kind_id.nil?
  end

  def mark_document_exception(kind = nil, extra_exception_kind_id: nil)
    errors.clear
    if bank_statement.month.closed?
      errors.add(:base, Month::CLOSED)
      return self
    end

    extra_id = extra_exception_kind_id.presence
    kind_value = kind.presence&.to_s

    if extra_id && kind_value
      errors.add(:base, UNKNOWN_KIND)
      return self
    end

    if extra_id
      mark_extra(extra_id)
    else
      mark_base(kind_value)
    end
    self
  end

  def unmark_document_exception
    errors.clear
    if bank_statement.month.closed?
      errors.add(:base, Month::CLOSED)
      return self
    end

    update!(document_exception_kind: nil, extra_exception_kind_id: nil)
    self
  end

  private

  def mark_extra(extra_id)
    extra = ExtraExceptionKind.lock.find_by(id: extra_id)
    unless extra&.active? && extra.organization_id == bank_statement.month.organization_id
      errors.add(:base, UNKNOWN_KIND)
      return
    end
    if match_id.present?
      errors.add(:base, MATCHED)
      return
    end

    update!(document_exception_kind: nil, extra_exception_kind_id: extra.id)
  rescue ActiveRecord::InvalidForeignKey
    errors.add(:base, UNKNOWN_KIND)
  end

  def mark_base(kind_value)
    unless %w[bank_fee accountant_fee].include?(kind_value.to_s)
      errors.add(:base, UNKNOWN_KIND)
      return
    end
    if match_id.present?
      errors.add(:base, MATCHED)
      return
    end

    update!(document_exception_kind: kind_value, extra_exception_kind_id: nil)
  end

  def dissolve_own_match
    return if match_id.nil?

    Match.find_by(id: match_id)&.dissolve
  end
end
