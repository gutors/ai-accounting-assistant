require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Tax id mask", type: :system do
  before do
    driven_by :cuprite, screen_size: [ 1280, 900 ], options: {
      browser_options: { "no-sandbox": nil },
      process_timeout: 30,
      timeout: 20
    }
  end

  def sign_in_through_google(account)
    stub_google_oauth(email: account.email, uid: account.google_uid)
    visit "/auth/google_oauth2/callback"
    expect(page).to have_css("header nav")
  end

  it "cadastro tax_id types CPF then CNPJ grouping" do
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/setup"

    field = find("#tax_id")
    expect(field.value).to eq("")
    "11222333000".chars.each { |digit| field.send_keys(digit) }
    expect(field.value).to eq("112.223.330-00")
    field.send_keys("1")
    field.send_keys("8")
    expect(field.value).to eq("11.222.333/0001-8")
    field.send_keys("1")
    expect(field.value).to eq("11.222.333/0001-81")
  end

  it "cadastro tax_id drops a fifteenth digit" do
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/setup"

    field = find("#tax_id")
    "11222333000181".chars.each { |digit| field.send_keys(digit) }
    expect(field.value).to eq("11.222.333/0001-81")
    field.send_keys("9")
    expect(field.value).to eq("11.222.333/0001-81")
  end

  it "edit accountant prefills formatted CNPJ" do
    account, organization = plant_coordinator
    persist_standing_accountant(organization)
    sign_in_through_google(account)
    visit "/setup?edit=accountant"

    expect(find("#tax_id").value).to eq("11.222.333/0001-81")
  end

  it "edit accountant prefills formatted CPF" do
    account, organization = plant_coordinator
    organization.update_accountant(presentation_name: "Ana Contábil", tax_id: "39053344705")
    sign_in_through_google(account)
    visit "/setup?edit=accountant"

    expect(find("#tax_id").value).to eq("390.533.447-05")
  end
end
