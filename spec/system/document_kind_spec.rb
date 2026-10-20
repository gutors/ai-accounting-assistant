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

  it "insert empty square hides Tipo until identify" do
    account, _organization = plant_submitter
    sign_in_through_google(account)
    visit "/supporting_documents"

    within("form[action='/supporting_documents']") do
      expect(find("#kind", visible: :all)).not_to be_visible
      expect(page).not_to have_css("#xml")
      expect(page).to have_css("#file", visible: :all)
    end
  end
end
