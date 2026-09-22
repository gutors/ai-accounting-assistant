require "rails_helper"

RSpec.describe "db/seeds.rb" do
  it "loading seeds.rb when not development persists no gutors@gmail.com Account" do
    expect(Rails.env.development?).to be(false)

    expect { load Rails.root.join("db/seeds.rb") }
      .not_to change { Account.where(email: "gutors@gmail.com").count }
  end

  it "loading seeds.rb in development plants ONG Exemplo and gutors@gmail.com" do
    allow(Rails.env).to receive(:development?).and_return(true)

    load Rails.root.join("db/seeds.rb")

    expect(Organization.count).to eq(1)
    expect(Account.count).to eq(1)
    account = Account.find_by!(email: "gutors@gmail.com")
    expect(account.google_uid).to be_nil
    organization = Organization.find_by!(name: "ONG Exemplo")
    expect(Access.count).to eq(1)
    access = Access.find_by!(account: account, organization: organization)
    expect(access.kind).to eq("coordinator")
  end

  it "README local note states development db:seed persists ONG Exemplo and gutors@gmail.com" do
    note = Rails.root.join("README.md").read[/## Estado.*?^## /m]

    expect(note).to include("bin/rails db:seed")
    expect(note).to include("development")
    expect(note).to include("ONG Exemplo")
    expect(note).to include("gutors@gmail.com")
    expect(note).to include("coordenador")
  end
end
