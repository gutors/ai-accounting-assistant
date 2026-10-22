require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Money mask", type: :system do
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

  def write_upload(name, content)
    path = Rails.root.join("tmp", name)
    FileUtils.mkdir_p(path.dirname)
    File.binwrite(path, content)
    path
  end

  def type_digits(locator)
    field = find(locator)
    field.send_keys("1")
    expect(field.value).to eq("0,01")
    field.send_keys("0")
    expect(field.value).to eq("0,10")
    field.send_keys("0")
    expect(field.value).to eq("1,00")
  end

  it "insert amount types 1 0 0 as 0,01 0,10 1,00" do
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/supporting_documents"
    photo_path = write_upload("recibo.jpg", "jpeg-bytes")

    attach_file "file", photo_path, make_visible: true
    expect(page).to have_css("h2", text: "Incluir documento")
    expect(page).not_to have_css(".lote-head", text: "Situação")
    expect(page).to have_field("kind", with: "Recibo", readonly: true)
    expect(page).to have_field("amount", visible: true)

    field = find("#amount")
    expect(field.value).to eq("")
    type_digits("#amount")
  end

  it "Editar amount prefills 155,00 after interactive" do
    account, organization = plant_coordinator
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    sign_in_through_google(account)
    visit "/supporting_documents/#{document.id}/edit"

    expect(find("#amount").value).to eq("155,00")
  end

  it "justification amount types 1 0 0 as 0,01 0,10 1,00" do
    _coord, organization = plant_coordinator
    account, _ = plant_submitter(organization: organization)
    sign_in_through_google(account)
    visit "/supporting_documents"

    field = find("#justification_amount")
    expect(field.value).to eq("0,00")
    type_digits("#justification_amount")
  end

  it "justification amount prefills 300,00 after interactive" do
    _coord, organization = plant_coordinator
    account, _ = plant_submitter(organization: organization)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    Justification.declare(organization: organization, account: account, amount: "300,00", supporting_document_ids: [ document.id ])
    justification = Justification.last
    sign_in_through_google(account)
    visit "/supporting_documents"

    expect(find("#justification_amount_#{justification.id}", visible: :all).value).to eq("300,00")
  end
end
