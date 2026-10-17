require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Document identify chrome", type: :system do
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

  it "Limpar after identify XML returns empty square" do
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/supporting_documents"
    xml_path = write_upload("proc-nfe.xml", authorized_nfe_xml)

    attach_file "file", xml_path, make_visible: true
    expect(page).to have_field("arquivo", with: "XML", disabled: true)
    expect(SupportingDocument.count).to eq(0)

    click_button "Limpar"

    expect(page).to have_css("[data-document-identify-target=wait]", visible: true, text: "Inclua o documento. Valor, data e favorecido saem do arquivo.")
    expect(page).not_to have_css("#amount", visible: true)
    expect(SupportingDocument.count).to eq(0)
  end

  it "identify pdf shows the file in the proof square" do
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/supporting_documents"
    pdf_path = write_upload("nota.pdf", pngs_to_pdf(ocr_png("blank.png")))

    attach_file "file", pdf_path, make_visible: true

    expect(page).to have_css("#identify-preview embed[src^='blob:']")
    expect(page).to have_css("#identify-preview", text: "Foto · nota.pdf")
    expect(page).to have_css("#identify-preview button", text: "Limpar")
  end

  it "identify photo shows the image in the proof square" do
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/supporting_documents"
    photo = Rails.root.join("spec/fixtures/files/ocr/amount_only.jpg")

    attach_file "file", photo, make_visible: true

    expect(page).to have_css("#identify-preview img[src^='blob:']")
    expect(page).to have_css("#identify-preview", text: "amount_only.jpg")
  end

  it "identify in flight shows Identificando o arquivo" do
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/supporting_documents"
    page.execute_script(<<~JS)
      const orig = window.fetch.bind(window)
      window.fetch = (url, opts) => {
        if (String(url).includes("/supporting_documents/identify")) {
          return new Promise((resolve) => {
            window.setTimeout(() => orig(url, opts).then(resolve), 800)
          })
        }
        return orig(url, opts)
      }
    JS
    xml_path = write_upload("proc-nfe.xml", authorized_nfe_xml)

    attach_file "file", xml_path, make_visible: true

    expect(page).to have_content("Identificando o arquivo…")
  end
end
