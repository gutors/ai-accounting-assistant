require "rails_helper"

RSpec.describe SetupDesk, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  def desk_for(organization, item: nil, edit: nil, bank_accounts: nil, extra_exception_kinds: nil)
    SetupDesk.new(
      organization,
      bank_accounts: bank_accounts || organization.bank_accounts.to_a,
      extra_exception_kinds: extra_exception_kinds || organization.extra_exception_kinds.to_a,
      item: item,
      edit: edit
    )
  end

  it "absent item selects first incomplete" do
    organization = create_organization!(name: "ONG")
    persist_standing_accountant(organization)

    expect(desk_for(organization, item: nil).selected).to eq("archive")
  end

  it "empty item selects first incomplete" do
    organization = create_organization!(name: "ONG")
    persist_standing_accountant(organization)

    expect(desk_for(organization, item: "").selected).to eq("archive")
  end

  it "unknown item selects first incomplete" do
    organization = create_organization!(name: "ONG")
    persist_standing_accountant(organization)

    expect(desk_for(organization, item: "nope").selected).to eq("archive")
  end

  it "complete setup selects accountant" do
    organization = create_organization!(name: "ONG")
    persist_standing_accountant(organization)
    persist_standing_archive(organization)
    organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")

    expect(desk_for(organization.reload).selected).to eq("accountant")
  end

  it "extras is never incomplete" do
    organization = create_organization!(name: "ONG")
    organization.update!(bank_fee_exception_active: false, accountant_fee_exception_active: false)

    desk = desk_for(organization)
    expect(desk.incomplete?("extras")).to eq(false)
    expect(desk.rows.find { |row| row.key == "extras" }.blocked?).to eq(false)
  end
end
