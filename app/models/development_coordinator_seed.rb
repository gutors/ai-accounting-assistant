class DevelopmentCoordinatorSeed
  EMAIL = "gutors@gmail.com"
  ORGANIZATION_NAME = "ONG Exemplo"

  def self.plant!
    return if Account.exists?(email: EMAIL)

    ActiveRecord::Base.transaction do
      organization = Organization.create!(name: ORGANIZATION_NAME)
      account = Account.create!(email: EMAIL)
      Access.create!(account: account, organization: organization, kind: :coordinator)
    end
  end
end
