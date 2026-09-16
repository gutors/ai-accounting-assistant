class Organization < ApplicationRecord
  has_many :accesses, dependent: :restrict_with_exception
  has_many :invites, dependent: :destroy

  validates :name, presence: true
end
