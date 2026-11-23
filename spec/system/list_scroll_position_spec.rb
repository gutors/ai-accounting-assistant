require "rails_helper"
require "capybara/cuprite"

RSpec.describe "List scroll position", type: :system do
  before do
    driven_by :cuprite, screen_size: [ 1280, 620 ], options: {
      browser_options: { "no-sandbox": nil },
      process_timeout: 30,
      timeout: 20
    }
    page.current_window.resize_to(1280, 620)
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

  def scroll_to_control(control, block: "center")
    page.execute_script("arguments[0].scrollIntoView({ block: arguments[1] })", control, block)
    scroll = scroll_position
    expect(scroll).to be_positive
    scroll
  end

  def scroll_position
    page.evaluate_script("window.scrollY")
  end

  def keyboard_activate(control)
    page.execute_script("arguments[0].focus({ preventScroll: true })", control)
    page.driver.browser.keyboard.type(:enter)
  end

  def expect_scroll_at(previous, shortened: false)
    current, maximum = page.evaluate_script("[window.scrollY, document.documentElement.scrollHeight - window.innerHeight]")
    expect(maximum).to be < previous if shortened
    expect(current).to be_within(1).of([ previous, maximum ].min)
  end

  def document_row_ids
    all("#sem-mes li[data-document-id]").map { |row| row["data-document-id"].to_i }
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
    documents = plant_documents(organization, account)
    sign_in(account)
    visit "/supporting_documents?sort=amount&dir=asc"

    within "#sem-mes" do
      fill_in "Favorecido", with: "Mercado 02"
      apply = find_button("Filtrar")
      scroll = scroll_to_control(apply, block: "start")
      keyboard_activate(apply)
      expect(page).to have_css("li[data-row=document]", count: 1)
      expect(document_row_ids).to eq([ documents[1].id ])
      expect_query(q: "Mercado 02", sort: "amount", dir: "asc")
      expect_scroll_at(scroll, shortened: true)

      scroll = scroll_position
      keyboard_activate(find_link("Limpar"))
      expect(page).to have_css("li[data-row=document]", count: 28)
      expect(document_row_ids).to eq(documents.reverse.map(&:id))
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
    22.times { |i| plant_inflow(statement, 1_000 + i, history: "Entrada cedo") }
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
    find("#month-payments summary").click

    within "#month-documents" do
      scroll = scroll_to_control(find_link("Favorecido"))
      click_link "Favorecido"
      expect(page).to have_css("[aria-sort=descending] a", text: "Favorecido")
      expect(first("li[data-document-id]")["data-document-id"]).to eq(documents.last.id.to_s)
      expect_query(pool_sort: "payee", pool_dir: "desc", payments_sort: "amount")
      expect_scroll_at(scroll)
    end
    expect(page).to have_css("#month-inflows:not([open])")
    expect(page).to have_css("#month-payments:not([open])")

    find("#month-documents summary").click
    find("#month-inflows summary").click
    within "#month-inflows" do
      scroll = scroll_to_control(find_link("Data"))
      click_link "Data"
      expect(page).to have_css("[aria-sort=descending] a", text: "Data")
      expect(first("li[data-row=inflow]")).to have_text("Entrada tarde")
      expect_query(inflows_sort: "date", inflows_dir: "desc", pool_sort: "payee", payments_sort: "amount")
      expect_scroll_at(scroll)
    end
    expect(page).to have_css("#month-payments:not([open])")
    expect(page).to have_css("#month-documents:not([open])")
  end

  it "changes and clears the month account in place" do
    account, organization = plant_coordinator
    month, statement = plant_month(organization)
    other_account = BankAccount.create_for(organization: organization, name: "Conta secundária", compe: "001")
    other_statement = month.bank_statements.create!(bank_account: other_account)
    plant_payment(other_statement, 1_000, history: "Pagamento secundário")
    plant_inflow(other_statement, 1_000, history: "Recebimento secundário")
    plant_inflow(statement, 1_000, history: "Recebimento principal")
    28.times { |i| plant_payment(statement, 2_000 + i, history: "Pagamento principal") }
    sign_in(account)
    visit "/months/2026-05"

    bank = find_link("Conta secundária")
    scroll = scroll_to_control(bank, block: "start")
    keyboard_activate(bank)
    expect(page).to have_css('[aria-current=true]', text: "Conta secundária")
    expect(page).to have_css("li[data-row=payment]", count: 1)
    expect(first("li[data-row=payment]")).to have_text("Pagamento secundário")
    expect(page).to have_css("li[data-row=inflow]", count: 1)
    expect(first("li[data-row=inflow]")).to have_text("Recebimento secundário")
    expect(page).to have_link("Casar pagamentos", href: "/months/2026-05/matches?bank_account_id=#{other_account.id}")
    expect_query(bank_account_id: other_account.id.to_s)
    expect_scroll_at(scroll, shortened: true)

    scroll = scroll_position
    keyboard_activate(find_link("Todas"))
    expect(page).to have_css('[aria-current=true]', text: "Todas")
    expect(page).to have_css("li[data-row=payment]", count: 29)
    expect(all("li[data-row=inflow]").map(&:text)).to contain_exactly(
      a_string_including("Recebimento principal"), a_string_including("Recebimento secundário")
    )
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
      keyboard_activate(date)
      expect(page).to have_css("[aria-sort=ascending] a:focus", text: "Data")
      expect_scroll_at(scroll)

      fill_in "Favorecido", with: "Mercado 02"
      apply = find_button("Filtrar")
      scroll = scroll_to_control(apply)
      keyboard_activate(apply)
      expect(page).to have_link("Limpar")
      expect(page).to have_css("input:focus[value=Filtrar]")
      expect_scroll_at(scroll)

      clear = find_link("Limpar")
      scroll = scroll_position
      keyboard_activate(clear)
      expect(page).to have_no_link("Limpar")
      expect(page).to have_css("input:focus#filter_q")
      expect_scroll_at(scroll)
    end
  end

  it "restores list results through history and reload" do
    account, organization = plant_coordinator
    documents = plant_documents(organization, account)
    documents.first.update!(amount_cents: 50)
    amount_order = documents.drop(1) + [ documents.first ]
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
    expect(document_row_ids).to eq(documents.map(&:id))

    page.go_forward
    expect(page).to have_css("#sem-mes [aria-sort=descending] a", text: "Valor")
    expect_query(sort: "amount", dir: "desc")
    expect(document_row_ids).to eq(amount_order.map(&:id))

    page.refresh
    expect(page).to have_css("#sem-mes [aria-sort=descending] a", text: "Valor")
    expect(document_row_ids).to eq(amount_order.map(&:id))
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
