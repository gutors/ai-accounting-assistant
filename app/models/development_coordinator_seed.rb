class DevelopmentCoordinatorSeed
  EMAIL = "gutors@gmail.com"
  ORGANIZATION_NAME = "ONG Exemplo"

  def self.plant!
    return if Account.exists?(email: EMAIL)

    ActiveRecord::Base.transaction do
      account = Account.create!(email: EMAIL)
      organization = Organization.create!(name: ORGANIZATION_NAME, principal_coordinator_account: account)
      Access.create!(account: account, organization: organization, kind: :coordinator)
    end
  end
end
