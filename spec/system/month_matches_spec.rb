require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Month matches layout", type: :system do
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

  def plant_open_matches
    account, organization = plant_coordinator
    month, statement = plant_month(organization)
    statement.bank_account.update!(name: "Conta Principal")
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 11))
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    plant_recibo(organization, account, payee: "Mercado Menos", amount: "200,00", date: "2026-05-10")
    plant_recibo(organization, account, payee: "Mercado Mais", amount: "250,00", date: "2026-05-09")
    [ account, organization, month ]
  end

  it "match-split is two columns at 1100px stacked below with ledger-pay 3px at 768px" do
    account, _organization, _month = plant_open_matches
    sign_in_through_google(account)

    visit "/months/2026-05/matches"
    expect(page).to have_css(".match-split")

    page.driver.resize(1100, 900)
    columns = page.evaluate_script(<<~JS)
      (function() {
        const split = document.querySelector(".match-split");
        const style = getComputedStyle(split);
        const tracks = style.gridTemplateColumns.split(" ").map((value) => parseFloat(value));
        const headings = Array.from(split.querySelectorAll("h2")).map((node) => node.textContent.trim());
        return { display: style.display, tracks, headings, trackCount: tracks.length };
      })()
    JS
    expect(columns["display"]).to eq("grid")
    expect(columns["headings"]).to eq([ "Pagamentos", "Documentos sem casamento" ])
    expect(columns["trackCount"]).to eq(2)
    expect(columns["tracks"][0]).to be > columns["tracks"][1]

    page.driver.resize(1099, 900)
    stacked = page.evaluate_script(<<~JS)
      (function() {
        const split = document.querySelector(".match-split");
        const style = getComputedStyle(split);
        const tracks = style.gridTemplateColumns.trim() === "none"
          ? []
          : style.gridTemplateColumns.split(" ").map((value) => parseFloat(value)).filter((value) => !Number.isNaN(value));
        const headings = Array.from(split.querySelectorAll("h2")).map((node) => node.textContent.trim());
        return { trackCount: tracks.length, headings };
      })()
    JS
    expect(stacked["trackCount"]).to eq(1)
    expect(stacked["headings"]).to eq([ "Pagamentos", "Documentos sem casamento" ])

    source = Rails.root.join("app/assets/tailwind/application.css").read
    expect(source).to include("@media (min-width: 1100px)")
    expect(source).to include("@media (min-width: 768px)")

    page.driver.resize(768, 900)
    density = page.evaluate_script(<<~JS)
      (function() {
        const row = document.querySelector('li[data-row="payment"]');
        const pool = document.querySelector('li[data-row="pool-document"]');
        const child = row.firstElementChild;
        const rowStyle = getComputedStyle(row);
        const childStyle = getComputedStyle(child);
        return {
          rowDisplay: rowStyle.display,
          poolDisplay: pool ? getComputedStyle(pool).display : null,
          paddingTop: childStyle.paddingTop,
          paddingBottom: childStyle.paddingBottom,
          borderLeft: rowStyle.borderLeftWidth,
          className: row.className
        };
      })()
    JS
    expect(density["rowDisplay"]).to eq("grid")
    expect(density["poolDisplay"]).to eq("grid")
    expect(density["className"]).to include("ledger-pay")
    expect(density["paddingTop"]).to eq("3px")
    expect(density["paddingBottom"]).to eq("3px")
    expect(density["borderLeft"]).to eq("3px")
  end

  it "totalling line sums and verdicts including empty side" do
    account, _organization, _month = plant_open_matches
    sign_in_through_google(account)
    visit "/months/2026-05/matches"

    payment = find('li[data-row="payment"][data-status="missing"] input[type="checkbox"]')
    padaria = find('li[data-row="pool-document"]', text: "Padaria Central").find('input[type="checkbox"]')
    menos = find('li[data-row="pool-document"]', text: "Mercado Menos").find('input[type="checkbox"]')
    mais = find('li[data-row="pool-document"]', text: "Mercado Mais").find('input[type="checkbox"]')

    payment.click
    padaria.click
    within(".match-confirm") do
      expect(page).to have_text("Pagamentos R$ 220,00")
      expect(page).to have_text("Documentos R$ 220,00")
      expect(page).to have_text("Soma igual")
    end
    ink = page.evaluate_script(<<~JS)
      (function() {
        const line = document.querySelector(".match-confirm");
        const style = getComputedStyle(line);
        return { borderTopWidth: style.borderTopWidth, borderTopColor: style.borderTopColor };
      })()
    JS
    expect(ink["borderTopWidth"]).to eq("1px")

    padaria.click
    menos.click
    within(".match-confirm") do
      expect(page).to have_text("Documentos R$ 200,00")
      expect(page).to have_text("Documentos somam menos")
      expect(page).to have_no_text("Soma igual")
    end

    menos.click
    mais.click
    within(".match-confirm") do
      expect(page).to have_text("Documentos R$ 250,00")
      expect(page).to have_text("Documentos somam mais")
    end

    mais.click
    within(".match-confirm") do
      expect(page).to have_text("Documentos R$ 0,00")
      expect(page).to have_text("Pagamentos R$ 220,00")
      expect(page).to have_no_text("Soma igual")
      expect(page).to have_no_text("Documentos somam menos")
      expect(page).to have_no_text("Documentos somam mais")
    end

    payment.click
    padaria.click
    within(".match-confirm") do
      expect(page).to have_text("Pagamentos R$ 0,00")
      expect(page).to have_text("Documentos R$ 220,00")
      expect(page).to have_no_text("Soma igual")
    end
  end
end
