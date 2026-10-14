require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Month overview layout", type: :system do
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

  it "month Pagamentos ledger-overview-pay 3px grid at 768px" do
    account, organization = plant_coordinator
    _month, statement = plant_month(organization)
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 11))
    sign_in_through_google(account)

    visit "/months/2026-05"
    expect(page).to have_css("details.month-fold", text: "Pagamentos")

    source = Rails.root.join("app/assets/tailwind/application.css").read
    expect(source).to include("@media (min-width: 768px)")
    expect(source).to include(".ledger-overview-pay")

    page.driver.resize(768, 900)
    density = page.evaluate_script(<<~JS)
      (function() {
        const row = document.querySelector('li[data-row="payment"]');
        const child = row.firstElementChild;
        const rowStyle = getComputedStyle(row);
        const childStyle = getComputedStyle(child);
        const head = document.querySelector(".ledger-overview-pay.ledger-head");
        const headLabels = head ? Array.from(head.children).map((node) => node.textContent.trim()) : [];
        return {
          rowDisplay: rowStyle.display,
          paddingTop: childStyle.paddingTop,
          paddingBottom: childStyle.paddingBottom,
          className: row.className,
          headLabels: headLabels
        };
      })()
    JS
    expect(density["rowDisplay"]).to eq("grid")
    expect(density["className"]).to include("ledger-overview-pay")
    expect(density["paddingTop"]).to eq("3px")
    expect(density["paddingBottom"]).to eq("3px")
    expect(density["headLabels"]).to eq([ "Data", "Histórico", "Valor", "Status", "Documento" ])
  end
end
