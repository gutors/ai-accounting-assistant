require "rails_helper"
require "rake"

RSpec.describe "coordinator:bootstrap" do
  before(:all) do
    Rails.application.load_tasks
  end

  def invoke_bootstrap
    status = 0
    begin
      Rake::Task["coordinator:bootstrap"].reenable
      Rake::Task["coordinator:bootstrap"].invoke
    rescue SystemExit => e
      status = e.status || 1
    end
    status
  end

  it "bootstrap persists Organization Account and coordinator Access" do
    status = with_env(
      "ORGANIZATION_NAME" => "ONG Plantada",
      "COORDINATOR_EMAIL" => "  Coord@Example.com "
    ) { invoke_bootstrap }

    expect(status).to eq(0)
    expect(Organization.where(name: "ONG Plantada").count).to eq(1)
    account = Account.find_by!(email: "coord@example.com")
    organization = Organization.find_by!(name: "ONG Plantada")
    access = Access.find_by!(account: account, organization: organization)
    expect(access.kind).to eq("coordinator")
  end

  it "bootstrap rejects missing and invalid COORDINATOR_EMAIL" do
    [
      { "ORGANIZATION_NAME" => "ONG", "COORDINATOR_EMAIL" => nil },
      { "ORGANIZATION_NAME" => "ONG", "COORDINATOR_EMAIL" => "not-an-email" }
    ].each do |env|
      expect do
        status = with_env(env) { invoke_bootstrap }
        expect(status).not_to eq(0)
      end.not_to change(Organization, :count)
      expect(Account.count).to eq(0)
      expect(Access.count).to eq(0)
    end
  end

  it "bootstrap rejects an email that already has an Account" do
    Account.create!(email: "coord@example.com")

    expect do
      status = with_env(
        "ORGANIZATION_NAME" => "ONG Nova",
        "COORDINATOR_EMAIL" => "coord@example.com"
      ) { invoke_bootstrap }
      expect(status).not_to eq(0)
    end.not_to change(Account, :count)

    expect(Organization.find_by(name: "ONG Nova")).to be_nil
  end

  it "bootstrap with a case-different organization name persists nothing and exits non-zero" do
    Organization.create!(name: "ONG Norte")
    counts = [ Organization.count, Account.count, Access.count ]
    source = Rails.root.join("lib/tasks/coordinator.rake").read
    expect(source).to include('abort "an Account already exists for that email"')
    expect(source).to include("Organization.create!")
    expect(source).not_to include("rescue")

    status = 0
    with_env(
      "ORGANIZATION_NAME" => "ong norte",
      "COORDINATOR_EMAIL" => "novo@exemplo.org"
    ) do
      begin
        Rake::Task["coordinator:bootstrap"].reenable
        Rake::Task["coordinator:bootstrap"].invoke
      rescue SystemExit => e
        status = e.status || 1
      rescue StandardError
        status = 1
      end
    end

    expect(status).not_to eq(0)
    expect([ Organization.count, Account.count, Access.count ]).to eq(counts)
    expect(Account.find_by(email: "novo@exemplo.org")).to be_nil
    expect(Organization.where("lower((name)::text) = ?", "ong norte").count).to eq(1)
  end
end
