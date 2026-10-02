class Invite < ApplicationRecord
  belongs_to :organization

  enum :kind, { coordinator: "coordinator", submitter: "submitter" }, validate: true
  enum :last_delivery, { sent: "sent", failed: "failed" }, validate: true

  before_validation :normalize_email

  validates :email, presence: true, uniqueness: { scope: :organization_id }
  validate :email_must_be_well_formed
  validate :email_must_not_have_standing_access

  def self.create_pending(organization:, email:, kind: :coordinator)
    invite = new(organization: organization, email: email, kind: kind)
    invite.save
    invite
  rescue ActiveRecord::RecordNotUnique
    invite.errors.add(:email, :taken)
    invite
  end

  def accept!(account)
    transaction do
      organization.accesses.create!(account: account, kind: kind)
      destroy!
    end
  end

  private

  def normalize_email
    self.email = NormalizedEmail.normalize(email)
  end

  def email_must_be_well_formed
    errors.add(:email, :invalid) unless NormalizedEmail.valid?(email)
  end

  def email_must_not_have_standing_access
    return if email.blank? || organization.nil?

    if organization.accesses.joins(:account).exists?(accounts: { email: email })
      errors.add(:email, :taken)
    end
  end
end
