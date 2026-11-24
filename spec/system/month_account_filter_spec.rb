require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Month account filter", type: :system do
  before do
    driven_by :cuprite, screen_size: [ 1037, 700 ], options: { browser_options: { "no-sandbox": nil } }
    @account, @organization = plant_coordinator
    @month, @statement = plant_month(@organization)
    @other = BankAccount.create_for(organization: @organization, name: "Conta Reserva", compe: "001")
    stub_google_oauth(email: @account.email, uid: @account.google_uid)
    visit "/auth/google_oauth2/callback"
  end

  it "opens home" do
    visit "/months/2026-05"
    click_link "Voltar ao início"
    expect(page).to have_current_path("/")
  end

  it "shows the account selector" do
    visit "/months/2026-05"
    expect(page).to have_select("Filtrar por conta bancária", options: [ "Todas as contas", "Conta Principal", "Conta Reserva" ], selected: "Todas as contas")
    expect(find_field("Filtrar por conta bancária")["aria-describedby"]).to eq("month-account-filter-scope")
    expect(page).to have_text("Aplica-se aos pagamentos e recebimentos.")
    @month.update!(accounts_confirmed: false)
    visit "/months/2026-05"
    expect(page).to have_no_field("Filtrar por conta bancária")
  end

  it "shows empty account messages" do
    visit "/months/2026-05"
    select "Conta Reserva", from: "Filtrar por conta bancária"
    expect(page).to have_text("Nenhum pagamento nesta conta.")
    expect(page).to have_text("Nenhum recebimento nesta conta.")
  end

  it "keeps month totals" do
    plant_payment(@statement, 1_000)
    visit "/months/2026-05"
    select "Conta Reserva", from: "Filtrar por conta bancária"
    expect(page).to have_text("1 pagamento com documento faltante.")
    expect(page).to have_text("Falta o extrato de 1 conta ativa.")
  end

  it "fits a phone viewport" do
    page.current_window.resize_to(390, 800)
    visit "/months/2026-05"
    expect(page).to have_text("Fechamento do mês")
    expect(page).to have_link("Voltar ao início")
    expect(page).to have_field("Filtrar por conta bancária")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be true
  end
end
