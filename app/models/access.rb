class Access < ApplicationRecord
  belongs_to :account
  belongs_to :organization

  enum :kind, { coordinator: "coordinator", submitter: "submitter" }, validate: true

  validates :account_id, uniqueness: { scope: :organization_id }

  def destroy
    transaction do
      coordinators = self.class.coordinator.where(organization_id: organization_id).lock.to_a
      if coordinator? && coordinators.size <= 1
        errors.add(:base, :last_coordinator)
        return false
      end
      super
    end
  end
end
