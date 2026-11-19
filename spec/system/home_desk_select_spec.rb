require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Home desk select", type: :system do
  before do
    driven_by :cuprite, screen_size: [ 903, 970 ], options: {
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

  it "people pin stays in the viewport while Meses scrolls" do
    account, organization = plant_coordinator
    (1..12).each do |month|
      Month.open(organization: organization, year_month: format("2026-%02d", month))
    end
    sign_in_through_google(account)
    visit "/"
    page.current_window.resize_to(903, 970)

    expect(page.evaluate_script(<<~JS)).to eq(true)
      (function () {
        var pin = document.querySelector(".desk-index-pin");
        var scroll = document.querySelector(".desk-index-scroll");
        if (!pin || !scroll) return false;
        var r = pin.getBoundingClientRect();
        scroll.scrollTop = scroll.scrollHeight;
        var after = pin.getBoundingClientRect();
        return r.bottom <= window.innerHeight && after.bottom <= window.innerHeight && after.height > 0;
      })();
    JS
  end

  it "org list closes on Escape and outside click" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "ONG Norte")
    org_b = create_organization!(name: "ONG Sul")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    sign_in_through_google(account)
    visit "/"

    button = find('header [aria-haspopup="listbox"]')
    expect(button["aria-expanded"]).to eq("false")
    button.click
    expect(button["aria-expanded"]).to eq("true")
    expect(page).to have_css("#org-list", visible: true)
    find("body").send_keys(:escape)
    expect(button["aria-expanded"]).to eq("false")

    button.click
    expect(button["aria-expanded"]).to eq("true")
    find("h2", text: "Meses").click
    expect(button["aria-expanded"]).to eq("false")
  end

  it "Convidar Coordenador posts coordinator_invites and Submitter posts submitter_invites" do
    account, organization = plant_coordinator
    sign_in_through_google(account)
    visit "/?desk=people"

    with_env("MAIL_FROM" => "venda@example.com") do
      fill_in "E-mail", with: "coord-guest@example.com"
      select "Coordenador", from: "invite-kind"
      click_button "Convidar"
    end
    expect(organization.invites.find_by!(email: "coord-guest@example.com").kind).to eq("coordinator")

    visit "/?desk=people"
    with_env("MAIL_FROM" => "venda@example.com") do
      fill_in "E-mail", with: "sub-guest@example.com"
      select "Submitter", from: "invite-kind"
      click_button "Convidar"
    end
    expect(organization.invites.find_by!(email: "sub-guest@example.com").kind).to eq("submitter")
  end
end
