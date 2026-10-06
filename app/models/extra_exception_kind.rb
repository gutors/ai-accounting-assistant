class ExtraExceptionKind < ApplicationRecord
  BASE_NAMES = [ "Tarifa bancária", "Honorário do contador" ].freeze
  BASE_JUSTIFICATIONS = {
    "Tarifa bancária" => "Tarifa cobrada pelo banco; não há documento fiscal a anexar.",
    "Honorário do contador" => "Honorário do contador neste fechamento; isento de documento de suporte."
  }.freeze

  belongs_to :organization
  has_many :payments, dependent: :restrict_with_exception

  before_validation :normalize_name, :normalize_justification

  validates :name, presence: true, uniqueness: { scope: :organization_id, case_sensitive: false }
  validates :justification, presence: true
  validate :name_is_not_base

  def self.create_for(organization:, name:, justification:)
    record = new(organization: organization, name: name, justification: justification)
    record.save
    record
  rescue ActiveRecord::RecordNotUnique
    record.errors.add(:name, :taken)
    record
  end

  def apply_active(value)
    self.active = ActiveModel::Type::Boolean.new.cast(value)
    save
  end

  def destroy_if_unused
    errors.clear
    transaction do
      lock!
      if payments.exists?
        errors.add(:base, :restrict_dependent_destroy)
        raise ActiveRecord::Rollback
      end
      destroy!
    end
    errors.empty?
  rescue ActiveRecord::InvalidForeignKey, ActiveRecord::RecordNotDestroyed, ActiveRecord::DeleteRestrictionError
    errors.add(:base, :restrict_dependent_destroy)
    false
  end

  private

  def normalize_name
    self.name = name.to_s.strip.presence
  end

  def normalize_justification
    self.justification = justification.to_s.strip.presence
  end

  def name_is_not_base
    return if name.blank?

    errors.add(:name, :taken) if BASE_NAMES.any? { |base| base.casecmp?(name) }
  end
end
