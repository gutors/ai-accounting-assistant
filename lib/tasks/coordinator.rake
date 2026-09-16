namespace :coordinator do
  desc "Plant the first organization and coordinator Account"
  task bootstrap: :environment do
    name = ENV["ORGANIZATION_NAME"].to_s
    raw_email = ENV["COORDINATOR_EMAIL"]

    abort "COORDINATOR_EMAIL is required" unless NormalizedEmail.valid?(raw_email)
    abort "ORGANIZATION_NAME is required" if name.blank?

    email = NormalizedEmail.normalize(raw_email)
    abort "an Account already exists for that email" if Account.exists?(email: email)

    ActiveRecord::Base.transaction do
      organization = Organization.create!(name: name)
      account = Account.create!(email: email)
      Access.create!(account: account, organization: organization, kind: :coordinator)
    end
  end
end
