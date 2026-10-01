require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Toast", type: :system do
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

  def invite_and_see_toast
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/"
    with_env("MAIL_FROM" => "venda@example.com") do
      within("form[action='/coordinator_invites']") do
        fill_in "email", with: "guest@example.com"
        click_button "Convidar"
      end
    end
    expect(page).to have_css("[data-toast]")
  end

  it "Fechar removes the toast before timeout" do
    invite_and_see_toast
    click_button "Fechar"
    expect(page).to have_no_css("[data-toast]", wait: 1)
  end

  it "toast is gone after 5000 ms" do
    invite_and_see_toast
    expect(page).to have_no_css("[data-toast]", wait: 6)
  end

  it "toast timeout stays 5000 ms under prefers-reduced-motion" do
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/"
    page.execute_script(<<~JS)
      window.matchMedia = function(query) {
        return {
          matches: query.indexOf("prefers-reduced-motion") !== -1,
          media: query,
          addEventListener: function() {},
          removeEventListener: function() {}
        };
      };
    JS
    with_env("MAIL_FROM" => "venda@example.com") do
      within("form[action='/coordinator_invites']") do
        fill_in "email", with: "guest@example.com"
        click_button "Convidar"
      end
    end
    expect(page).to have_css("[data-toast]", wait: 1)
    expect(page).to have_no_css("[data-toast]", wait: 6)
  end
end
