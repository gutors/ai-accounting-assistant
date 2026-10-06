require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Document kind chrome", type: :system do
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

  def open_insert_form
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/supporting_documents"
    find("form[action='/supporting_documents']")
  end

  it "insert Recibo hides chave and xml" do
    open_insert_form

    within("form[action='/supporting_documents']") do
      select "Recibo", from: "kind"
      chave = find("#chave", visible: :all)
      xml = find("#xml", visible: :all)
      expect(chave).not_to be_visible
      expect(xml).not_to be_visible
      expect(chave).to be_disabled
      expect(xml).to be_disabled
      photo = find("#photo", visible: :all)
      expect(find("[data-file-field='photo']")).to be_visible
      expect(photo).not_to be_disabled
    end
  end

  it "insert Nota fiscal shows chave and xml again" do
    open_insert_form

    within("form[action='/supporting_documents']") do
      select "Recibo", from: "kind"
      select "Nota fiscal", from: "kind"
      chave = find("#chave")
      xml = find("#xml", visible: :all)
      expect(chave).to be_visible
      expect(find("[data-file-field='xml']")).to be_visible
      expect(chave).not_to be_disabled
      expect(xml).not_to be_disabled
    end
  end
end
