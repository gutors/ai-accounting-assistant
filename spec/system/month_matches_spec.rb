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

  it "workspace has two columns at 1100px and stacks on narrow screens" do
    account, _organization, _month = plant_open_matches
    sign_in_through_google(account)

    visit "/months/2026-05/matches"
    expect(page).to have_css(".match-workspace")

    page.current_window.resize_to(1100, 900)
    columns = page.evaluate_script(<<~JS)
      (function() {
        const split = document.querySelector(".match-workspace");
        const style = getComputedStyle(split);
        const tracks = style.gridTemplateColumns.split(" ").map((value) => parseFloat(value));
        const headings = Array.from(split.querySelectorAll("h2")).map((node) => node.textContent.trim());
        return { display: style.display, tracks, headings, trackCount: tracks.length };
      })()
    JS
    expect(columns["display"]).to eq("grid")
    expect(columns["headings"]).to eq([ "Pagamento em análise", "Documentos selecionados" ])
    expect(columns["trackCount"]).to eq(2)
    expect(columns["tracks"][0]).to be > columns["tracks"][1]

    page.current_window.resize_to(375, 900)
    stacked = page.evaluate_script(<<~JS)
      (function() {
        const split = document.querySelector(".match-workspace");
        const style = getComputedStyle(split);
        const tracks = style.gridTemplateColumns.trim() === "none"
          ? []
          : style.gridTemplateColumns.split(" ").map((value) => parseFloat(value)).filter((value) => !Number.isNaN(value));
        const headings = Array.from(split.querySelectorAll("h2")).map((node) => node.textContent.trim());
        return { trackCount: tracks.length, headings };
      })()
    JS
    expect(stacked["trackCount"]).to eq(1)
    expect(stacked["headings"]).to eq([ "Pagamento em análise", "Documentos selecionados" ])

    source = Rails.root.join("app/assets/tailwind/application.css").read
    expect(source).to include("@media (min-width: 1100px)")
    expect(source).to include("@media (min-width: 768px)")

    page.current_window.resize_to(768, 900)
    density = page.evaluate_script(<<~JS)
      (function() {
        const row = document.querySelector('[data-row="payment"]');
        const pool = document.querySelector('[data-row="pool-document"] input:checked').closest('[data-row="pool-document"]');
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
    expect(density["rowDisplay"]).to eq("flex")
    expect(density["poolDisplay"]).to eq("flex")
    expect(density["className"]).to include("match-picker-row")
  end

  it "totalling line sums and verdicts including empty side" do
    account, _organization, _month = plant_open_matches
    sign_in_through_google(account)
    visit "/months/2026-05/matches"

    click_button "Adicionar documentos"
    payment = find('[data-row="payment"] input[type="checkbox"]')
    padaria = find('[data-row="pool-document"]', text: "Padaria Central").find('input[type="checkbox"]')
    menos = find('[data-row="pool-document"]', text: "Mercado Menos").find('input[type="checkbox"]')
    mais = find('[data-row="pool-document"]', text: "Mercado Mais").find('input[type="checkbox"]')
    within("#match-confirm") do
      expect(page).to have_text("Pagamentos R$ 220,00")
      expect(page).to have_text("Documentos R$ 220,00")
      expect(page).to have_text("Soma igual")
    end

    padaria.click
    menos.click
    within("#match-confirm") do
      expect(page).to have_text("Documentos R$ 200,00")
      expect(page).to have_text("Documentos somam menos")
      expect(page).to have_no_text("Soma igual")
    end

    menos.click
    mais.click
    within("#match-confirm") do
      expect(page).to have_text("Documentos R$ 250,00")
      expect(page).to have_text("Documentos somam mais")
    end

    mais.click
    within("#match-confirm") do
      expect(page).to have_text("Documentos R$ 0,00")
      expect(page).to have_text("Pagamentos R$ 220,00")
      expect(page).to have_no_text("Soma igual")
      expect(page).to have_no_text("Documentos somam menos")
      expect(page).to have_no_text("Documentos somam mais")
    end

    payment.click
    padaria.click
    within("#match-confirm") do
      expect(page).to have_text("Pagamentos R$ 0,00")
      expect(page).to have_text("Documentos R$ 220,00")
      expect(page).to have_no_text("Soma igual")
    end
  end

  it "workspace groups confirmation and compact observation with the payment" do
    account, _organization, _month = plant_open_matches
    sign_in_through_google(account)
    visit "/months/2026-05/matches"

    expect(page).to have_css("h2", text: "Pagamento em análise")
    expect(page).to have_css("#match-confirm")
    styles = page.evaluate_script(<<~JS)
      (function() {
        const band = document.querySelector(".match-workspace");
        const confirm = document.querySelector("#match-confirm");
        const bandStyle = getComputedStyle(band);
        const confirmStyle = getComputedStyle(confirm);
        return {
          containsHeading: band.querySelector("h2") && band.querySelector("h2").textContent.trim() === "Pagamento em análise",
          insideConfirm: confirm.contains(band),
          observationClosed: band.querySelector("details") && !band.querySelector("details").open,
          confirmBorderTopWidth: confirmStyle.borderTopWidth
        };
      })()
    JS
    expect(styles["containsHeading"]).to eq(true)
    expect(styles["insideConfirm"]).to eq(true)
    expect(styles["observationClosed"]).to eq(true)
    expect(styles["confirmBorderTopWidth"]).to eq("0px")
  end

  it "equal suggestion is selected but requires explicit confirmation" do
    account, _organization, _month = plant_open_matches
    sign_in_through_google(account)
    visit "/months/2026-05/matches"

    expect(page).to have_text("Soma igual")
    expect(Match.count).to eq(0)
    click_button "Confirmar casamento"
    expect(page).to have_current_path("/months/2026-05/matches")
    expect(Match.count).to eq(1)
    expect(page).to have_css("[data-match-id]", text: "Pix enviado — Padaria Central")
    expect(page).to have_no_css('[data-row="pool-document"]', text: "Padaria Central")
  end

  it "lesser suggestion checks rows and does not persist" do
    account, organization = plant_coordinator
    month, statement = plant_month(organization)
    plant_payment(statement, 150000, history: "TED — Aluguel sede", occurred_on: Date.new(2026, 5, 11))
    plant_recibo(organization, account, payee: "Imobiliária Serra", amount: "1400,00", date: "2026-05-11")
    sign_in_through_google(account)
    visit "/months/2026-05/matches"

    expect(Match.count).to eq(0)
    pay = find('[data-row="payment"]', text: "TED — Aluguel sede")
    expect(pay.find('input[type="checkbox"]')).to be_checked
    doc = find('[data-row="pool-document"]', text: "Imobiliária Serra")
    expect(doc.find('input[type="checkbox"]')).to be_checked
    within("#match-confirm") do
      expect(page).to have_text("Documentos somam menos")
      expect(find("#observation_match", visible: false).value).to eq("")
    end
  end
end
