module RecordHelpers
  def plant_coordinator(email: "coord@example.com", organization_name: "ONG Norte", google_uid: "uid-#{email}")
    organization = Organization.create!(name: organization_name)
    account = Account.create!(email: email, google_uid: google_uid)
    Access.create!(account: account, organization: organization, kind: :coordinator)
    [ account, organization ]
  end

  def truncate_product_tables
    BankAccount.delete_all
    Invite.delete_all
    Access.delete_all
    Account.delete_all
    Organization.delete_all
  end
end
