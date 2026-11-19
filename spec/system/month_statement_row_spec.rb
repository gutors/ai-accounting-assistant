require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Month statement row", type: :system do
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

  def upload(name, content)
    path = Rails.root.join("tmp", name)
    FileUtils.mkdir_p(path.dirname)
    File.binwrite(path, content)
    path
  end

  def stage(account, *paths)
    picker = account.find("[data-statement-row-target='picker']", visible: :all)
    within(account) do
      find("[data-statement-row-target='picker']", visible: :all).set(paths)
    end
    picker
  end

  def account_row(bank_account)
    find("li[data-row='bank-account'][data-bank-account-id='#{bank_account.id}']")
  end

  def visible_icons(bank_account)
    account_row(bank_account).all(".ledger-row-actions .ledger-action-icon", visible: true)
      .map { |node| node["aria-label"] }
  end

  def document_lines(bank_account)
    account_row(bank_account).all("[data-cell='documents'] p", visible: true).map { |node| node.text.strip }
  end

  def open_month(account_name: "Conta Principal")
    account, organization = plant_coordinator
    sign_in_through_google(account)
    bank_account = BankAccount.create_for(organization: organization, name: account_name, compe: "001")
    Month.open(organization: organization, year_month: "2026-05")
    visit "/months/2026-05"
    [ account, organization, bank_account ]
  end

  it "picking a spreadsheet alone stages Planilha and offers the send" do
    _account, _organization, bank_account = open_month

    stage(account_row(bank_account), upload("extrato.xlsx", "sheet-bytes"))

    expect(document_lines(bank_account)).to eq([ "Planilha extrato.xlsx" ])
    expect(visible_icons(bank_account)).to eq([ "Enviar extrato", "Descartar arquivos escolhidos" ])
  end

  it "picking a PDF alone withholds the send and keeps the hint" do
    _account, _organization, bank_account = open_month

    stage(account_row(bank_account), upload("extrato.pdf", "%PDF-1.1"))

    expect(document_lines(bank_account)).to eq([ "Pdf extrato.pdf", "A planilha é obrigatória" ])
    expect(visible_icons(bank_account)).to eq([ "Incluir extrato", "Descartar arquivos escolhidos" ])
  end

  it "picking both files stages Pdf above Planilha with the send" do
    _account, _organization, bank_account = open_month

    stage(account_row(bank_account), upload("extrato.pdf", "%PDF-1.1"), upload("extrato.xlsx", "sheet-bytes"))

    expect(document_lines(bank_account)).to eq([ "Pdf extrato.pdf", "Planilha extrato.xlsx" ])
    expect(visible_icons(bank_account)).to eq([ "Enviar extrato", "Descartar arquivos escolhidos" ])
  end

  it "two files of each kind stage the first of each" do
    _account, _organization, bank_account = open_month

    stage(
      account_row(bank_account),
      upload("primeiro.pdf", "%PDF-1.1"),
      upload("segundo.pdf", "%PDF-1.1"),
      upload("primeira.xlsx", "sheet-bytes"),
      upload("segunda.xlsx", "sheet-bytes")
    )

    expect(document_lines(bank_account)).to eq([ "Pdf primeiro.pdf", "Planilha primeira.xlsx" ])
  end

  it "nota txt and extrato ofx are refused and a staged xlsx clears the sentence" do
    _account, _organization, bank_account = open_month

    stage(account_row(bank_account), upload("nota.txt", "texto"))

    expect(account_row(bank_account)).to have_css(".statement-refusal", text: "Só PDF, .csv ou .xlsx")
    expect(visible_icons(bank_account)).to eq([ "Incluir extrato" ])

    stage(account_row(bank_account), upload("extrato.ofx", "OFXHEADER"))

    expect(document_lines(bank_account)).to include("Só PDF, .csv ou .xlsx")
    expect(account_row(bank_account)).not_to have_css(".statement-file")

    stage(account_row(bank_account), upload("extrato.xlsx", "sheet-bytes"))

    expect(account_row(bank_account)).not_to have_css(".statement-refusal")
    expect(document_lines(bank_account)).to eq([ "Planilha extrato.xlsx" ])
  end

  it "sending the staged files persists the statement and toasts" do
    _account, _organization, bank_account = open_month
    stage(
      account_row(bank_account),
      upload("extrato-maio-2026.pdf", "%PDF-1.1"),
      upload("extrato-maio-2026.csv", File.read(Rails.root.join("spec/fixtures/files/extrato-maio-2026.csv")))
    )

    within(account_row(bank_account)) { find("[data-statement-row-target='send']").click }

    expect(page).to have_current_path("/months/2026-05")
    expect(document_lines(bank_account)).to eq([ "Pdf extrato-maio-2026.pdf", "Planilha extrato-maio-2026.csv" ])
    expect(account_row(bank_account)).to have_text("Presente")
    expect(page).to have_css("[data-toast]")
  end

  it "descartar clears the staged files without posting" do
    _account, organization, bank_account = open_month
    stage(account_row(bank_account), upload("extrato.xlsx", "sheet-bytes"), upload("extrato.pdf", "%PDF-1.1"))

    within(account_row(bank_account)) { find("[data-statement-row-target='discard']").click }

    expect(document_lines(bank_account)).to eq([ "A planilha é obrigatória" ])
    expect(visible_icons(bank_account)).to eq([ "Incluir extrato" ])
    expect(organization.reload.months.first.bank_statements.count).to eq(0)
  end

  it "every Pagamentos row measures at most 48px across five statuses" do
    account, organization = plant_coordinator
    sign_in_through_google(account)
    month, statement = plant_month(organization)
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")

    missing = plant_payment(statement, 120_000, history: "Pix - Enviado — 06/05 10:14 MARCIO ANTONIO ZANNONI")
    matched = plant_payment(statement, 84_270, history: "Pix enviado — Atacado De Confeccoes Forte Sul")
    fee = plant_payment(statement, 3_990, history: "Tarifa Pacote de Serviços — Cobrança referente 11/05/2026")
    fee.update!(document_exception_kind: "bank_fee")
    accountant = plant_payment(statement, 50_000, history: "Honorário do contador — maio")
    accountant.update!(document_exception_kind: "accountant_fee")
    extra = plant_payment(statement, 26_000, history: "Doação recebida em espécie do sócio")
    extra.update!(extra_exception_kind: kind)

    document = plant_recibo(organization, account, payee: "Atacado de Confecções Forte Sul", amount: "842,70")
    Match.confirm(month: month, payments: [ matched ], supporting_documents: [ document ], observation: "desconto não documentado")

    visit "/months/2026-05"

    heights = JSON.parse(page.evaluate_script(<<~JS))
      (function () {
        function textLines(node) {
          var range = document.createRange();
          range.selectNodeContents(node);
          var tops = [];
          Array.from(range.getClientRects()).forEach(function (rect) {
            if (tops.indexOf(Math.round(rect.top)) === -1) tops.push(Math.round(rect.top));
          });
          return tops.length;
        }

        return JSON.stringify(Array.from(document.querySelectorAll('li[data-row="payment"]')).map(function (row) {
          var cells = [ ".pay-history", ".pay-status", ".pay-document" ].map(function (selector) {
            var node = row.querySelector(selector);
            return node ? textLines(node) : 0;
          });
          return {
            status: row.getAttribute("data-status"),
            height: Math.round(row.getBoundingClientRect().height),
            textLines: cells
          };
        }));
      })()
    JS

    expect(heights.size).to eq(5)
    heights.each do |row|
      expect(row["height"]).to be <= 48
      row["textLines"].each { |lines| expect(lines).to be <= 1 }
    end

    expect(account_row_for(missing)).to have_css(".pay-history", visible: true)
    expect(account_row_for(matched)).to have_css(".pay-status", text: "Casado")
    expect(account_row_for(fee)).to have_css(".pay-status", text: "Tarifa bancária")
    expect(account_row_for(accountant)).to have_css(".pay-status", text: "Honorário do contador")
    expect(account_row_for(extra)).to have_css(".pay-status", text: "Doação")
  end

  def account_row_for(payment)
    find("li[data-row='payment'][data-payment-id='#{payment.id}']")
  end

  it "390px pagamentos stacks two lines without horizontal scroll" do
    account, organization = plant_coordinator
    sign_in_through_google(account)
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 124_000, history: "Pix - Enviado — 11/05 16:43 HILARIO CESAR DUARTE PEDROSA")
    document = plant_recibo(organization, account, payee: "Hilario Cesar Duarte Pedrosa", amount: "1240,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
    _payment = payment

    visit "/months/2026-05"
    page.current_window.resize_to(390, 844)

    metrics = page.evaluate_script(<<~JS)
      (function () {
        var row = document.querySelector('li[data-row="payment"]');
        var date = row.querySelector("time");
        var amount = row.querySelector('[data-cell="amount"]');
        var history = row.querySelector(".pay-history");
        var status = row.querySelector('[data-cell="status"]');
        return {
          scrollWidth: document.documentElement.scrollWidth,
          clientWidth: document.documentElement.clientWidth,
          dateTop: date.getBoundingClientRect().top,
          amountTop: amount.getBoundingClientRect().top,
          historyTop: history.getBoundingClientRect().top,
          statusTop: status.getBoundingClientRect().top,
          documentDisplay: getComputedStyle(row.querySelector('[data-cell="document"]')).display,
          height: row.getBoundingClientRect().height
        };
      })()
    JS

    expect(metrics["scrollWidth"]).to eq(390)
    expect(metrics["clientWidth"]).to eq(390)
    expect(metrics["dateTop"]).to eq(metrics["amountTop"])
    expect(metrics["historyTop"]).to eq(metrics["statusTop"])
    expect(metrics["historyTop"]).to be > metrics["dateTop"]
    expect(metrics["documentDisplay"]).to eq("none")
    expect(metrics["height"]).to be <= 60
  end
end
