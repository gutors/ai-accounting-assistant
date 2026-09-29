require "rails_helper"

RSpec.describe Access, type: :model do
  it "rejects a second Access for the same Account and Organization" do
    account, organization = plant_coordinator

    duplicate = Access.new(account: account, organization: organization, kind: :coordinator)

    expect(duplicate).not_to be_valid
  end

  it "kind enum members are coordinator and submitter" do
    expect(Access.kinds.keys).to contain_exactly("coordinator", "submitter")

    _account, organization = plant_coordinator
    expect(organization.accesses.first.kind).to eq("coordinator")

    invite = Invite.create_pending(organization: organization, email: "guest@example.com")
    expect(invite.kind).to eq("coordinator")
  end

  it "destroy last submitter Access is allowed" do
    _coordinator, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    access = organization.accesses.submitter.find_by!(account: submitter)

    expect(access.destroy).to be_truthy
    expect(Access.find_by(id: access.id)).to be_nil
    expect(organization.accesses.coordinator.count).to eq(1)
  end

  it "destroy is rejected when it is the last coordinator Access" do
    _account, organization = plant_coordinator
    access = organization.accesses.coordinator.first

    expect(access.destroy).to be(false)
    expect(access.errors.added?(:base, :last_coordinator)).to be(true)
    expect(access).to be_persisted
    expect(organization.accesses.coordinator.count).to eq(1)
  end

  describe "concurrent destroy of last two persists exactly one" do
    self.use_transactional_tests = false

    it "concurrent destroy of last two persists exactly one" do
      truncate_product_tables
      organization = create_organization!(name: "ONG")
      account_a = Account.create!(email: "a@example.com")
      account_b = Account.create!(email: "b@example.com")
      access_a = Access.create!(account: account_a, organization: organization, kind: :coordinator)
      access_b = Access.create!(account: account_b, organization: organization, kind: :coordinator)

      threads = [
        Thread.new { ActiveRecord::Base.connection_pool.with_connection { access_a.destroy } },
        Thread.new { ActiveRecord::Base.connection_pool.with_connection { access_b.destroy } }
      ]
      threads.each(&:join)

      expect(organization.accesses.coordinator.count).to eq(1)
    ensure
      truncate_product_tables
    end
  end
end
