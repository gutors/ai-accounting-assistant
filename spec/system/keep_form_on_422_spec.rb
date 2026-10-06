require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Keep form on 422", type: :system do
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

  it "insert Recibo XML 422 keeps the chosen xml file" do
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/supporting_documents"
    xml_path = write_upload("nota.xml", "<nfe/>")

    within("form[action='/supporting_documents']") do
      fill_in "amount", with: "155,00"
      fill_in "date", with: "2026-05-11"
      fill_in "payee", with: "Padaria Central"
      fill_in "observation", with: "pago em dinheiro"
      attach_file "xml", xml_path
      select "Recibo", from: "kind"
      page.execute_script("document.getElementById('xml').disabled = false")
      click_button "Incluir documento"
    end

    expect(page).to have_css("[data-notice=error]", text: "Recibo não tem XML")
    expect(page).to have_css("[data-toast-kind=error]", text: "Recibo não tem XML")
    expect(page).to have_select("kind", selected: "Recibo")
    expect(page).to have_field("amount", with: "155,00")
    expect(page).to have_field("date", with: "2026-05-11")
    expect(page).to have_field("payee", with: "Padaria Central")
    expect(page).to have_field("observation", with: "pago em dinheiro")
    expect(find("#xml", visible: :all).value).to include("nota.xml")
  end

  it "insert 422 after Pronto still shows the error toast" do
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/supporting_documents"
    photo_path = write_upload("recibo.jpg", "jpeg-bytes")
    xml_path = write_upload("nota.xml", "<nfe/>")

    within("form[action='/supporting_documents']") do
      fill_in "amount", with: "155,00"
      fill_in "date", with: "2026-05-11"
      fill_in "payee", with: "Padaria Central"
      attach_file "photo", photo_path
      select "Recibo", from: "kind"
      click_button "Incluir documento"
    end
    expect(page).to have_css("[data-toast-kind=success]", text: "Pronto.")

    within("form[action='/supporting_documents']") do
      fill_in "amount", with: "155,00"
      fill_in "date", with: "2026-05-11"
      fill_in "payee", with: "Padaria Central"
      attach_file "xml", xml_path
      select "Recibo", from: "kind"
      page.execute_script("document.getElementById('xml').disabled = false")
      click_button "Incluir documento"
    end
    expect(page).to have_css("[data-notice=error]", text: "Recibo não tem XML")
    expect(page).to have_css("[data-toast-kind=error]", text: "Recibo não tem XML")
    expect(page).to have_css("#toast-host [data-toast-kind=error]")
  end

  it "Limpar clears insert photo without submit" do
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/supporting_documents"
    photo_path = write_upload("recibo.jpg", "jpeg-bytes")

    within("form[action='/supporting_documents']") do
      attach_file "photo", photo_path
      expect(find("#photo").value).to include("recibo.jpg")
      find("#photo").sibling("button", text: "Limpar").click
      expect(find("#photo").value).to eq("")
    end
    expect(page).to have_current_path("/supporting_documents")
  end

  it "Limpar clears A1 certificate without submit" do
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/setup"
    find("summary", text: "Instalar certificado").click
    cert_path = write_upload("cert.pfx", "pkcs12-bytes")

    within("form[action='/sefaz_certificate']") do
      attach_file "certificate", cert_path, make_visible: true
      expect(find("#certificate", visible: :all).value).to include("cert.pfx")
      find("#certificate").sibling("button", text: "Limpar").click
      expect(find("#certificate", visible: :all).value).to eq("")
    end
    expect(page).to have_current_path("/setup")
  end
end
