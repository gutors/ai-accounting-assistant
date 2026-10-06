require "rails_helper"
require "capybara/cuprite"

# Screen proofs for the visual identity (door 4): Chrome over CDP, one PNG per screen and viewport.
RSpec.describe "Screens", type: :system do
  before do
    driven_by :cuprite, screen_size: [ 1280, 900 ], options: {
      browser_options: { "no-sandbox": nil },
      process_timeout: 30,
      timeout: 15
    }
  end

  def viewports
    { 390 => 844, 1280 => 900 }
  end

  def screenshot_dir
    Rails.root.join("tmp/screenshots")
  end

  def screenshot_path(screen, width)
    screenshot_dir.join("#{screen}-#{width}.png").to_s
  end

  def plant_world
    coordinator, norte = plant_coordinator(email: "coord@example.com", organization_name: "ONG Norte")
    sul = create_organization!(name: "ONG Sul")
    Access.create!(account: coordinator, organization: sul, kind: :coordinator)
    submitter, _ = plant_submitter(email: "joao@example.com", organization: norte)
    Invite.create_pending(organization: norte, email: "guest@example.com", kind: :submitter)
    ready_to_close!(norte)
    norte.update!(accountant_tax_id: "39053344705", accountant_legal_name: "Contábil LTDA", accountant_pix_key: "contador@pix.example")
    ExtraExceptionKind.create_for(organization: norte, name: "Doação", justification: "Isento de documento de suporte.")

    principal = BankAccount.create_for(organization: norte, name: "Conta Principal", compe: "001", coordinates: "ag 1234 cc 56789-0")
    BankAccount.create_for(organization: norte, name: "Conta Alfa", compe: "033")

    april = Month.open(organization: norte, year_month: "2026-04")
    april.update!(closed: true)

    month = Month.open(organization: norte, year_month: "2026-05")
    statement = BankStatement.create!(month: month, bank_account: principal)
    attach_statement_files(statement)
    plant_inflow(statement, 6300)
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 11))
    papelaria = plant_payment(statement, 15500, history: "Pix enviado — Papelaria Norte", occurred_on: Date.new(2026, 5, 12))
    plant_payment(statement, 1550, history: "Tarifa Pacote de Serviços", occurred_on: Date.new(2026, 5, 12)).mark_document_exception("bank_fee")

    plant_recibo(norte, submitter, payee: "Padaria Central", amount: "220,00")
    SupportingDocument.insert(
      organization: norte, account: submitter, kind: "nota_fiscal", amount: "45,00", date: "2026-05-13",
      payee: "Mercado Silva", photo: photo_named("nota-mercado-silva.jpg"), observation: "material de limpeza",
      chave: "35240612345678000190550010000012341000012340"
    )
    papelaria_doc = plant_recibo(norte, coordinator, payee: "Papelaria Norte", amount: "155,00", date: "2026-05-12")
    Match.confirm(month: month, payments: [ papelaria ], supporting_documents: [ papelaria_doc ])

    { coordinator: coordinator, submitter: submitter }
  end

  def sign_in_through_google(account)
    stub_google_oauth(email: account.email, uid: account.google_uid)
    visit "/auth/google_oauth2/callback"
    expect(page).to have_css("header nav")
  end

  def sign_out
    Capybara.reset_session!
  end

  def at_viewport(width)
    page.driver.resize(width, viewports.fetch(width))
    yield
  end

  def wait_for_fonts
    page.evaluate_async_script("document.fonts.ready.then(() => arguments[0]())")
  end

  def shoot(screen, path)
    viewports.each_key do |width|
      at_viewport(width) do
        visit path
        wait_for_fonts
        page.save_screenshot(screenshot_path(screen, width), full: true)
      end
    end
  end

  def scroll_width
    page.evaluate_script("document.documentElement.scrollWidth")
  end

  def amount_cell_styles
    page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('li[data-row] [data-cell="amount"]')).map((el) => {
        const style = getComputedStyle(el);
        return [style.fontVariantNumeric, style.textAlign];
      })
    JS
  end

  it "saves one screenshot per screen and viewport" do
    accounts = plant_world
    FileUtils.mkdir_p(screenshot_dir)

    shoot("login", "/login")
    shoot("denied", "/denied")

    sign_in_through_google(accounts[:coordinator])
    shoot("home", "/")
    shoot("setup", "/setup")
    shoot("month-open", "/months/2026-05")
    shoot("month-closed", "/months/2026-04")
    sign_out

    sign_in_through_google(accounts[:submitter])
    shoot("documents", "/supporting_documents")

    expected = %w[login denied home setup month-open month-closed documents].product(viewports.keys).map { |screen, width| screenshot_path(screen, width) }
    expect(expected.size).to eq(14)
    expect(expected.reject { |file| File.file?(file) && File.size(file).positive? }).to be_empty
  end

  it "amount cells are tabular and right-aligned on month and documents" do
    accounts = plant_world
    sign_in_through_google(accounts[:coordinator])

    at_viewport(1280) do
      [ "/months/2026-05", "/supporting_documents" ].each do |path|
        visit path
        styles = amount_cell_styles
        expect(styles).not_to be_empty, "no amount cells on #{path}"
        styles.each do |numeric, align|
          expect(numeric).to include("tabular-nums")
          expect(align).to eq("right")
        end
      end
    end
  end

  it "month has no horizontal scroll at 390" do
    accounts = plant_world
    sign_in_through_google(accounts[:coordinator])

    at_viewport(390) do
      visit "/months/2026-05"
      expect(page).to have_css('li[data-status="missing"] details[open]')
      expect(scroll_width).to be <= 390
    end
  end

  it "home and setup have no horizontal scroll at 390" do
    accounts = plant_world
    sign_in_through_google(accounts[:coordinator])

    at_viewport(390) do
      visit "/"
      expect(page).to have_css("h1", text: "Início")
      expect(scroll_width).to be <= 390

      visit "/setup"
      expect(page).to have_css("h1", text: "Configuração")
      expect(scroll_width).to be <= 390
    end
  end

  it "documents has no horizontal scroll at 390" do
    accounts = plant_world
    sign_in_through_google(accounts[:submitter])

    at_viewport(390) do
      visit "/supporting_documents"
      find('li[data-row="document"] summary', text: "Editar", match: :first).click
      expect(page).to have_css('li[data-row="document"] details[open]')
      expect(scroll_width).to be <= 390
    end
  end
end
