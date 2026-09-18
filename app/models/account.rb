class Account < ApplicationRecord
  has_many :accesses, dependent: :restrict_with_exception
  has_many :organizations, through: :accesses
  has_many :coordinator_accesses, -> { coordinator }, class_name: "Access"
  has_many :coordinator_organizations, through: :coordinator_accesses, source: :organization
  has_many :supporting_documents, dependent: :restrict_with_exception

  before_validation :normalize_email

  validates :email, presence: true, uniqueness: true
  validate :email_must_be_well_formed
  validates :google_uid, uniqueness: true, allow_nil: true

  private

  def normalize_email
    self.email = NormalizedEmail.normalize(email)
  end

  def email_must_be_well_formed
    errors.add(:email, :invalid) unless NormalizedEmail.valid?(email)
  end
end
