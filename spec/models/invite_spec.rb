require "rails_helper"

RSpec.describe Invite, type: :model do
  it "persists kind coordinator" do
    organization = create_organization!(name: "ONG")
    invite = Invite.create_pending(organization: organization, email: "guest@example.com")

    expect(invite).to be_persisted
    expect(invite.kind).to eq("coordinator")
  end

  it "create_pending kind submitter persists submitter" do
    organization = create_organization!(name: "ONG")
    invite = Invite.create_pending(organization: organization, email: "guest@example.com", kind: :submitter)

    expect(invite).to be_persisted
    expect(invite.kind).to eq("submitter")
  end

  it "accept creates coordinator Access and deletes the Invite" do
    organization = create_organization!(name: "ONG")
    invite = Invite.create!(organization: organization, email: "guest@example.com", kind: :coordinator)
    account = Account.create!(email: "guest@example.com", google_uid: "uid-guest")

    invite.accept!(account)

    expect(Invite.find_by(id: invite.id)).to be_nil
    access = Access.find_by!(account: account, organization: organization)
    expect(access.kind).to eq("coordinator")
  end

  it "accept creates coordinator Access and does not write principal_coordinator_account_id" do
    organization = Organization.register_coordinator(name: "ONG Norte", email: "coordenador@exemplo.org")
    principal = organization.principal_coordinator_account
    invite = Invite.create!(organization: organization, email: "ana@exemplo.org", kind: :coordinator)
    account = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")

    invite.accept!(account)

    expect(Invite.find_by(id: invite.id)).to be_nil
    access = Access.find_by!(account: account, organization: organization)
    expect(access.kind).to eq("coordinator")
    expect(organization.reload.principal_coordinator_account).to eq(principal)
  end

  it "accept submitter creates submitter Access and deletes the Invite" do
    organization = create_organization!(name: "ONG")
    invite = Invite.create!(organization: organization, email: "guest@example.com", kind: :submitter)
    account = Account.create!(email: "guest@example.com", google_uid: "uid-guest")

    invite.accept!(account)

    expect(Invite.find_by(id: invite.id)).to be_nil
    access = Access.find_by!(account: account, organization: organization)
    expect(access.kind).to eq("submitter")
    expect(organization.accesses.coordinator.where(account: account)).to be_empty
  end

  it "last_delivery is sent or failed" do
    organization = create_organization!(name: "ONG")
    expect(Invite.last_deliveries.keys).to contain_exactly("sent", "failed")

    created = Invite.create_pending(organization: organization, email: "guest@example.com")
    expect(created).to be_persisted
    expect(created.last_delivery).to eq("sent")

    created.update!(last_delivery: :failed)
    expect(created.reload.last_delivery).to eq("failed")

    created.last_delivery = "unsent"
    expect(created).not_to be_valid
  end

  it "rejects standing Access of either kind, pending duplicate, and invalid email" do
    organization = create_organization!(name: "ONG")
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
      organization = create_organization!(name: "ONG")

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
      organization = create_organization!(name: "ONG")

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
