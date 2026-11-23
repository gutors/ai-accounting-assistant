require "rails_helper"
require "capybara/cuprite"

RSpec.describe "List scroll position", type: :system do
  before do
    driven_by :cuprite, screen_size: [ 1280, 620 ], options: {
      browser_options: { "no-sandbox": nil },
      process_timeout: 30,
      timeout: 20
    }
  end

  def sign_in(account)
    stub_google_oauth(email: account.email, uid: account.google_uid)
    visit "/auth/google_oauth2/callback"
    expect(page).to have_css("header nav")
  end

  def plant_documents(organization, account, prefix: "Mercado")
    (1..28).map do |number|
      plant_recibo(organization, account, payee: format("%s %02d", prefix, number),
        amount: "#{29 - number},00", date: "2026-05-#{number.to_s.rjust(2, '0')}")
    end
  end

  def scroll_to_control(control)
    page.execute_script("arguments[0].scrollIntoView({ block: 'center' })", control)
    scroll = page.evaluate_script("window.scrollY")
    expect(scroll).to be_positive
    scroll
  end

  def expect_scroll_at(previous)
    current, maximum = page.evaluate_script("[window.scrollY, document.documentElement.scrollHeight - window.innerHeight]")
    expect(current).to be_within(1).of([ previous, maximum ].min)
  end

  def expect_query(**expected)
    expect(Rack::Utils.parse_query(URI.parse(page.current_url).query)).to include(expected.stringify_keys)
  end

  shared_examples "an in-place document sort" do
    it "sorts Sem mês by Data and Valor in place" do
      account, organization = operator
      documents = plant_documents(organization, account)
      sign_in(account)
      visit "/supporting_documents"
      form = find(inclusion_form, visible: :all)
      page.execute_script("arguments[0].dataset.unsaved = 'retained'", form)

      within "#sem-mes" do
        scroll = scroll_to_control(find_link("Data"))
        click_link "Data"
        expect(page).to have_css("[aria-sort=ascending] a", text: "Data")
        expect(first("li[data-document-id]")["data-document-id"]).to eq(documents.first.id.to_s)
        expect_query(sort: "date", dir: "asc")
        expect_scroll_at(scroll)

        click_link "Valor"
        expect(page).to have_css("[aria-sort=descending] a", text: "Valor")
        expect(first("li[data-document-id]")["data-document-id"]).to eq(documents.first.id.to_s)
        expect_query(sort: "amount", dir: "desc")
        expect_scroll_at(scroll)

        click_link "Valor"
        expect(page).to have_css("[aria-sort=ascending] a", text: "Valor")
        expect(first("li[data-document-id]")["data-document-id"]).to eq(documents.last.id.to_s)
        expect_query(sort: "amount", dir: "asc")
        expect_scroll_at(scroll)
      end

      expect(page).to have_css("#{inclusion_form}[data-unsaved=retained]", visible: :all)
    end
  end

  context "for the coordinator" do
    let(:operator) { plant_coordinator }
    let(:inclusion_form) { "[data-controller=document-lote] form" }

    include_examples "an in-place document sort"
  end

  context "for the submitter" do
    let(:operator) { plant_submitter }
    let(:inclusion_form) { "form[data-controller=document-identify]" }

    include_examples "an in-place document sort"
  end

  it "filters and clears Sem mês in place" do
    account, organization = plant_coordinator
    plant_documents(organization, account)
    sign_in(account)
    visit "/supporting_documents?sort=amount&dir=asc"

    within "#sem-mes" do
      fill_in "Favorecido", with: "Mercado 02"
      scroll = scroll_to_control(find_button("Filtrar"))
      click_button "Filtrar"
      expect(page).to have_css("li[data-row=document]", count: 1, text: "Mercado 02")
      expect_query(q: "Mercado 02", sort: "amount", dir: "asc")
      expect_scroll_at(scroll)

      scroll = scroll_to_control(find_link("Limpar"))
      click_link "Limpar"
      expect(page).to have_css("li[data-row=document]", count: 28)
      expect(page).to have_no_link("Limpar")
      expect_query(sort: "amount", dir: "asc")
      expect(page.current_url).not_to include("q=")
      expect_scroll_at(scroll)
    end
  end

  it "sorts all three month lists in place" do
    account, organization = plant_coordinator
    _month, statement = plant_month(organization)
    documents = plant_documents(organization, account)
    cheap = plant_payment(statement, 1_000, occurred_on: Date.new(2026, 5, 11))
    expensive = plant_payment(statement, 2_000, occurred_on: Date.new(2026, 5, 12))
    plant_inflow(statement, 1_000, history: "Entrada cedo")
    statement.inflows.create!(occurred_on: Date.new(2026, 5, 12), amount_cents: 2_000, history: "Entrada tarde")
    sign_in(account)
    visit "/months/2026-05"
    find("#month-inflows summary").click

    within "#month-payments" do
      scroll = scroll_to_control(find_link("Valor"))
      click_link "Valor"
      expect(page).to have_css("[aria-sort=descending] a", text: "Valor")
      expect(all("li[data-payment-id]").map { |row| row["data-payment-id"] }).to eq([ expensive.id.to_s, cheap.id.to_s ])
      expect_query(payments_sort: "amount", payments_dir: "desc")
      expect_scroll_at(scroll)
    end
    expect(page).to have_css("#month-inflows:not([open])")

    within "#month-documents" do
      scroll = scroll_to_control(find_link("Favorecido"))
      click_link "Favorecido"
      expect(page).to have_css("[aria-sort=descending] a", text: "Favorecido")
      expect(first("li[data-document-id]")["data-document-id"]).to eq(documents.last.id.to_s)
      expect_query(pool_sort: "payee", pool_dir: "desc", payments_sort: "amount")
      expect_scroll_at(scroll)
    end
    expect(page).to have_css("#month-inflows:not([open])")

    find("#month-inflows summary").click
    within "#month-inflows" do
      scroll = scroll_to_control(find_link("Data"))
      click_link "Data"
      expect(page).to have_css("[aria-sort=descending] a", text: "Data")
      expect(first("li[data-row=inflow]")).to have_text("Entrada tarde")
      expect_query(inflows_sort: "date", inflows_dir: "desc", pool_sort: "payee", payments_sort: "amount")
      expect_scroll_at(scroll)
    end
  end

  it "changes and clears the month account in place" do
    account, organization = plant_coordinator
    month, statement = plant_month(organization)
    other_account = BankAccount.create_for(organization: organization, name: "Conta secundária", compe: "001")
    other_statement = month.bank_statements.create!(bank_account: other_account)
    plant_payment(other_statement, 1_000, history: "Pagamento secundário")
    28.times { |i| plant_payment(statement, 2_000 + i, history: "Pagamento principal") }
    sign_in(account)
    visit "/months/2026-05"

    scroll = scroll_to_control(find_link("Conta secundária"))
    click_link "Conta secundária"
    expect(page).to have_css('[aria-current=true]', text: "Conta secundária")
    expect(page).to have_css("li[data-row=payment]", count: 1, text: "Pagamento secundário")
    expect(page).to have_no_text("Pagamento principal")
    expect(page).to have_link("Casar pagamentos", href: "/months/2026-05/matches?bank_account_id=#{other_account.id}")
    expect_query(bank_account_id: other_account.id.to_s)
    expect_scroll_at(scroll)

    scroll = page.evaluate_script("window.scrollY")
    click_link "Todas"
    expect(page).to have_css('[aria-current=true]', text: "Todas")
    expect(page).to have_css("li[data-row=payment]", count: 29)
    expect(page).to have_link("Casar pagamentos", href: "/months/2026-05/matches")
    expect(page).to have_current_path("/months/2026-05")
    expect_scroll_at(scroll)
  end

  it "returns keyboard focus after a list update" do
    account, organization = plant_coordinator
    plant_documents(organization, account)
    sign_in(account)
    visit "/supporting_documents"

    within "#sem-mes" do
      date = find_link("Data")
      scroll = scroll_to_control(date)
      date.send_keys(:enter)
      expect(page).to have_css("[aria-sort=ascending] a:focus", text: "Data")
      expect_scroll_at(scroll)

      fill_in "Favorecido", with: "Mercado 02"
      apply = find_button("Filtrar")
      scroll = scroll_to_control(apply)
      apply.send_keys(:enter)
      expect(page).to have_link("Limpar")
      expect(page).to have_css("input:focus[value=Filtrar]")
      expect_scroll_at(scroll)

      clear = find_link("Limpar")
      scroll = scroll_to_control(clear)
      clear.send_keys(:enter)
      expect(page).to have_no_link("Limpar")
      expect(page).to have_css("input:focus#filter_q")
      expect_scroll_at(scroll)
    end
  end

  it "restores list results through history and reload" do
    account, organization = plant_coordinator
    documents = plant_documents(organization, account)
    sign_in(account)
    visit "/supporting_documents"

    page.execute_script(<<~JS)
      document.addEventListener("turbo:load", event => {
        document.documentElement.dataset.loadedQuery = new URL(event.detail.url).search;
      });
    JS

    within "#sem-mes" do
      click_link "Data"
      expect(page).to have_css("[aria-sort=ascending] a", text: "Data")
    end
    expect(page).to have_css("html[data-loaded-query='?dir=asc&sort=date']", visible: :all)

    within "#sem-mes" do
      click_link "Valor"
      expect(page).to have_css("[aria-sort=descending] a", text: "Valor")
    end

    page.go_back
    expect(page).to have_css("#sem-mes [aria-sort=ascending] a", text: "Data")
    expect_query(sort: "date", dir: "asc")
    expect(first("#sem-mes li[data-document-id]")["data-document-id"]).to eq(documents.first.id.to_s)

    page.go_forward
    expect(page).to have_css("#sem-mes [aria-sort=descending] a", text: "Valor")
    expect_query(sort: "amount", dir: "desc")

    page.refresh
    expect(page).to have_css("#sem-mes [aria-sort=descending] a", text: "Valor")
    expect(first("#sem-mes li[data-document-id]")["data-document-id"]).to eq(documents.first.id.to_s)
  end

  it "opens the full login page after session expiry" do
    account, organization = plant_coordinator
    plant_recibo(organization, account, payee: "Mercado", amount: "10,00")
    sign_in(account)
    visit "/supporting_documents"

    page.driver.browser.cookies.clear
    within("#sem-mes") { click_link "Valor" }

    expect(page).to have_current_path("/login")
    expect(page).to have_button("Entrar com Google")
    expect(page).to have_no_css("#sem-mes")
  end
end
