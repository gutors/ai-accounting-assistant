require "rails_helper"

RSpec.describe "Month statement row", type: :request do
  def open_month_with(account_name: "Conta Principal", compe: "001")
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: account_name, compe: compe)
    post "/months", params: { year_month: "2026-05" }
    [ account, organization, bank_account ]
  end

  def signed_open_month
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, statement = plant_month(organization)
    [ account, organization, month, statement ]
  end

  def statement_controls(account_row)
    account_row.css(".ledger-row-actions .ledger-action-icon")
  end

  def visible_controls(account_row)
    statement_controls(account_row).reject { |node| node.key?("hidden") }
  end

  it "open month account rows carry one statement icon and no disclosure summary" do
    _account, _organization, bank_account = open_month_with

    get "/months/2026-05"

    account_row = row(response.body, "bank-account", bank_account_id: bank_account.id)
    visible = visible_controls(account_row)
    expect(visible.size).to eq(1)
    expect(visible.first["aria-label"]).to eq("Incluir extrato")
    expect(statement_controls(account_row).size).to eq(3)
    expect(account_row.css("summary").map { |node| node.text.strip })
      .not_to include("Incluir extrato", "Substituir extrato")
    expect(account_row.text).not_to include("Incluir extrato")
    expect(account_row.text).not_to include("Substituir extrato")
  end

  it "open month present account row carries the pencil named Substituir extrato" do
    _account, _organization, _month, statement = signed_open_month
    attach_statement_files(statement)

    get "/months/2026-05"

    account_row = row(response.body, "bank-account", bank_account_id: statement.bank_account_id)
    visible = visible_controls(account_row)
    expect(visible.size).to eq(1)
    expect(visible.first["aria-label"]).to eq("Substituir extrato")
    expect(visible.first.at_css('path')["d"]).to include("M11.5 2.5")
    expect(account_row.text).not_to include("Substituir extrato")
  end

  it "account without statement shows only the planilha hint in Documentos" do
    _account, _organization, bank_account = open_month_with

    get "/months/2026-05"

    account_row = row(response.body, "bank-account", bank_account_id: bank_account.id)
    documents = account_row.at_css('[data-cell="documents"]')
    expect(documents.text.strip).to eq("A planilha é obrigatória")
    expect(documents.text).not_to include("Pdf")
    expect(documents.text).not_to include("Planilha ")
  end

  it "closed month rows have no statement control" do
    _account, organization, month, statement = signed_open_month
    attach_statement_files(statement)
    month.update!(closed: true)

    get "/months/2026-05"

    account_row = row(response.body, "bank-account", bank_account_id: statement.bank_account_id)
    expect(statement_controls(account_row)).to be_empty
    expect(account_row.at_css("form")).to be_nil
    expect(response.body).not_to include("Enviar extrato")
    expect(account_row.text).not_to include("Incluir extrato")
    expect(organization.bank_accounts.count).to eq(1)
  end

  it "refused POST re-renders with Envie a planilha and no staged files" do
    _account, _organization, bank_account = open_month_with

    post "/months/2026-05/bank_statements", params: { bank_account_id: bank_account.id, pdf: statement_pdf }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Envie a planilha")
    account_row = row(response.body, "bank-account", bank_account_id: bank_account.id)
    expect(statement_controls(account_row).first["aria-label"]).to eq("Incluir extrato")
    expect(account_row.at_css('[data-cell="documents"]').text.strip).to eq("A planilha é obrigatória")
  end

  it "long history document and status cells truncate and carry title" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, statement = plant_month(organization)
    history = "Pix - Enviado — 06/05 10:14 MARCIO ANTONIO ZANNONI DA SILVA E SOUZA"
    payment = plant_payment(statement, 120_000, history: history)
    document = plant_recibo(organization, account, payee: "Atacado de Confecções Forte Sul Limitada", amount: "1200,00")
    fee = plant_payment(statement, 3_990, history: "Tarifa pacote")
    fee.update!(document_exception_kind: "accountant_fee")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    get "/months/2026-05"

    payment_row = row(response.body, "payment", payment_id: payment.id)
    history_cell = payment_row.at_css(".pay-history")
    expect(history_cell.text.strip).to eq(history)
    expect(history_cell["title"]).to eq(history)
    account_cell = payment_row.at_css(".pay-account")
    expect(account_cell["title"]).to eq(statement.bank_account.name)
    document_cell = payment_row.at_css('[data-cell="document"]')
    expect(document_cell["class"]).to include("pay-document")
    expect(document_cell["title"]).to eq("Atacado de Confecções Forte Sul Limitada")

    wide_row = row(response.body, "payment", payment_id: fee.id)
    wide_status_cell = wide_row.at_css(".pay-status")
    expect(wide_status_cell.text.strip).to eq("Honorário do contador")
    expect(wide_status_cell["title"]).to eq("Honorário do contador")
    short_status = payment_row.at_css(".pay-status")
    expect(short_status.text.strip).to eq("Casado")
    expect(short_status["title"]).to eq("Casado")
  end

  it "Pagamentos omits the match observation that matches still shows" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22_000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ], observation: "desconto não documentado")

    get "/months/2026-05"

    payment_row = row(response.body, "payment", payment_id: payment.id)
    expect(payment_row.text).to include("Casado")
    expect(payment_row.text).not_to include("desconto não documentado")
    expect(payment_row.at_css('[data-cell="status"]').css("p").size).to eq(1)

    get "/months/2026-05/matches"

    expect(response.body).to include("desconto não documentado")
  end
end
