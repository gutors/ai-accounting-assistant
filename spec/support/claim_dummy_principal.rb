module ClaimDummyPrincipal
  def self.included(base)
    base.after_create :claim_dummy_principal
  end

  private

  def claim_dummy_principal
    return unless coordinator?
    return if organization.accesses.coordinator.where.not(id: id).exists?

    holder = organization.principal_coordinator_account
    return if holder && Access.exists?(account: holder, organization: organization, kind: :coordinator)

    organization.update_column(:principal_coordinator_account_id, account_id)
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    Access.include(ClaimDummyPrincipal) unless Access.included_modules.include?(ClaimDummyPrincipal)
  end
end
