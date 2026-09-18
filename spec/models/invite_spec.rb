require "rails_helper"

RSpec.describe Invite, type: :model do
  it "persists kind coordinator" do
    organization = Organization.create!(name: "ONG")
    invite = Invite.create_pending(organization: organization, email: "guest@example.com")

    expect(invite).to be_persisted
    expect(invite.kind).to eq("coordinator")
  end

  it "create_pending kind submitter persists submitter" do
    organization = Organization.create!(name: "ONG")
    invite = Invite.create_pending(organization: organization, email: "guest@example.com", kind: :submitter)

    expect(invite).to be_persisted
    expect(invite.kind).to eq("submitter")
  end

  it "accept creates coordinator Access and deletes the Invite" do
    organization = Organization.create!(name: "ONG")
    invite = Invite.create!(organization: organization, email: "guest@example.com", kind: :coordinator)
    account = Account.create!(email: "guest@example.com", google_uid: "uid-guest")

    invite.accept!(account)

    expect(Invite.find_by(id: invite.id)).to be_nil
    access = Access.find_by!(account: account, organization: organization)
    expect(access.kind).to eq("coordinator")
  end

  it "accept submitter creates submitter Access and deletes the Invite" do
    organization = Organization.create!(name: "ONG")
    invite = Invite.create!(organization: organization, email: "guest@example.com", kind: :submitter)
    account = Account.create!(email: "guest@example.com", google_uid: "uid-guest")

    invite.accept!(account)

    expect(Invite.find_by(id: invite.id)).to be_nil
    access = Access.find_by!(account: account, organization: organization)
    expect(access.kind).to eq("submitter")
    expect(organization.accesses.coordinator.where(account: account)).to be_empty
  end

  it "rejects standing Access of either kind, pending duplicate, and invalid email" do
    organization = Organization.create!(name: "ONG")
    standing_coord = Account.create!(email: "coord-standing@example.com")
    Access.create!(account: standing_coord, organization: organization, kind: :coordinator)
    standing_sub = Account.create!(email: "sub-standing@example.com")
    Access.create!(account: standing_sub, organization: organization, kind: :submitter)
    Invite.create!(organization: organization, email: "pending@example.com", kind: :coordinator)

    [
      "coord-standing@example.com",
      "sub-standing@example.com",
      "pending@example.com",
      "not-an-email"
    ].each do |email|
      invite = Invite.create_pending(organization: organization, email: email, kind: :submitter)
      expect(invite).not_to be_persisted
    end
  end

  describe "concurrent creates persist exactly one pending Invite" do
    self.use_transactional_tests = false

    it "concurrent creates persist exactly one pending Invite" do
      truncate_product_tables
      organization = Organization.create!(name: "ONG")

      run_in_parallel(2) do
        Invite.create_pending(organization: organization, email: "guest@example.com")
      rescue ActiveRecord::RecordNotUnique
        nil
      end

      expect(Invite.where(organization: organization, email: "guest@example.com").count).to eq(1)
    ensure
      truncate_product_tables
    end
  end

  describe "concurrent submitter creates persist exactly one pending Invite" do
    self.use_transactional_tests = false

    it "concurrent submitter creates persist exactly one pending Invite" do
      truncate_product_tables
      organization = Organization.create!(name: "ONG")

      run_in_parallel(2) do
        Invite.create_pending(organization: organization, email: "guest@example.com", kind: :submitter)
      rescue ActiveRecord::RecordNotUnique
        nil
      end

      expect(Invite.where(organization: organization, email: "guest@example.com").count).to eq(1)
    ensure
      truncate_product_tables
    end
  end
end
