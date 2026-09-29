require "rails_helper"

RSpec.describe BankAccount, type: :model do
  def organization
    @organization ||= create_organization!(name: "ONG")
  end

  it "create with COMPE 001 persists active account and parameterized slug" do
    account = BankAccount.create_for(organization: organization, name: "  Conta Principal  ", compe: "001")

    expect(account).to be_persisted
    expect(account).to be_active
    expect(account.bank.presentation_name).to eq("Banco do Brasil")
    expect(account.slug).to eq(ActiveSupport::Inflector.parameterize("Conta Principal"))
    expect(account.name).to eq("Conta Principal")
  end

  it "parameterize BB agencia 1234 is bb-agencia-1234" do
    account = BankAccount.create_for(organization: organization, name: "BB agência 1234", compe: "001")

    expect(account.slug).to eq("bb-agencia-1234")
  end

  it "allows two accounts at the same Bank" do
    first = BankAccount.create_for(organization: organization, name: "Conta 1", compe: "001")
    second = BankAccount.create_for(organization: organization, name: "Conta 2", compe: "001")

    expect(first).to be_persisted
    expect(second).to be_persisted
    expect(organization.bank_accounts.count).to eq(2)
  end

  it "persists trimmed coordinates" do
    account = BankAccount.create_for(organization: organization, name: "Principal", compe: "001", coordinates: "  ag 1234  ")

    expect(account.coordinates).to eq("ag 1234")
  end

  it "updating name regenerates slug" do
    account = BankAccount.create_for(organization: organization, name: "Antiga", compe: "001")

    expect(account.apply_from(name: "Nova Conta")).to be(true)
    expect(account.name).to eq("Nova Conta")
    expect(account.slug).to eq("nova-conta")
  end

  it "rejects a name whose slug collides including inactive" do
    existing = BankAccount.create_for(organization: organization, name: "Café", compe: "001")
    existing.apply_from(active: false)

    colliding = BankAccount.create_for(organization: organization, name: "Cafe", compe: "033")
    expect(colliding).not_to be_persisted

    other = BankAccount.create_for(organization: organization, name: "Outra", compe: "033")
    expect(other.apply_from(name: "Cafe")).to be(false)
  end

  it "rejects a name that parameterizes to empty" do
    account = BankAccount.create_for(organization: organization, name: "---", compe: "001")

    expect(account).not_to be_persisted
  end

  it "rejects COMPE not in the catalog" do
    account = BankAccount.create_for(organization: organization, name: "Principal", compe: "999")

    expect(account).not_to be_persisted
  end

  it "rejects duplicate name when the other account is inactive" do
    existing = BankAccount.create_for(organization: organization, name: "Principal", compe: "001")
    existing.apply_from(active: false)

    duplicate = BankAccount.create_for(organization: organization, name: "Principal", compe: "033")
    expect(duplicate).not_to be_persisted
  end

  it "deactivate keeps the row" do
    account = BankAccount.create_for(organization: organization, name: "Principal", compe: "001")

    expect(account.apply_from(active: false)).to be(true)
    expect(BankAccount.find(account.id)).not_to be_active
  end

  it "reactivate sets active true" do
    account = BankAccount.create_for(organization: organization, name: "Principal", compe: "001")
    account.apply_from(active: false)

    expect(account.apply_from(active: true)).to be(true)
    expect(account).to be_active
  end

  describe "concurrent creates persist exactly one BankAccount" do
    self.use_transactional_tests = false

    it "concurrent creates persist exactly one BankAccount" do
      truncate_product_tables
      org = create_organization!(name: "ONG")

      run_in_parallel(2) do
        BankAccount.create_for(organization: org, name: "Principal", compe: "001")
      rescue ActiveRecord::RecordNotUnique
        nil
      end

      expect(BankAccount.where(organization: org, name: "Principal").count).to eq(1)
    ensure
      truncate_product_tables
    end
  end
end
