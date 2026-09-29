require "rails_helper"

RSpec.describe Account, type: :model do
  it "rejects a second Account for the same normalized email" do
    Account.create!(email: "  Coord@Example.com ", google_uid: "uid-1")

    duplicate = Account.new(email: "coord@example.com", google_uid: "uid-2")

    expect(duplicate).not_to be_valid
    expect(Account.where(email: "coord@example.com").count).to eq(1)
  end

  it "rejects a second Account for the same Google uid" do
    Account.create!(email: "one@example.com", google_uid: "same-uid")

    duplicate = Account.new(email: "two@example.com", google_uid: "same-uid")

    expect(duplicate).not_to be_valid
  end

  it "organization_for_focus prefers a coordinator organization over a submitter organization" do
    account = Account.create!(email: "pessoa@exemplo.org", google_uid: "uid-pessoa")
    submitter_org = create_organization!(name: "ONG Leste")
    Access.create!(account: account, organization: submitter_org, kind: :submitter)
    coordinator_org = create_organization!(name: "ONG Sul", principal_coordinator_account: account)
    Access.create!(account: account, organization: coordinator_org, kind: :coordinator)

    expect(account.organization_for_focus).to eq(coordinator_org)
  end

  it "organization_for_focus is nil when the Account has no Access" do
    account = Account.create!(email: "seller@example.com", google_uid: "uid-seller")

    expect(account.organization_for_focus).to be_nil
  end
end
