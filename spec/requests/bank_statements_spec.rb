require "rails_helper"

RSpec.describe "Bank statements", type: :request do
  def open_with_account(compe: "001", name: "Conta Principal", coordinates: nil)
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: name, compe: compe, coordinates: coordinates)
    post "/months", params: { year_month: "2026-05" }
    [ account, organization, bank_account ]
  end

  it "POST BB xlsx persists statement Presente and filenames" do
    _account, organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(BankStatement.joins(:month).where(months: { organization_id: organization.id }).count).to eq(1)

    get "/months/2026-05"
    expect(response.body).to include("Presente")
    expect(response.body).to include("extrato-maio-2026.pdf")
    expect(response.body).to include("extrato-maio-2026.xlsx")
  end

  it "POST BB xlsx persists 18 Inflows and 13 Payments" do
    _account, _organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }

    statement = bank_account.bank_statements.last
    expect(statement.inflows.count).to eq(18)
    expect(statement.payments.count).to eq(13)
  end

  it "POST BB xlsx persists tarifa Payment 15500 cents" do
    _account, _organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }

    payment = bank_account.bank_statements.last.payments.find_by!(amount_cents: 15500)
    expect(payment.occurred_on).to eq(Date.new(2026, 5, 11))
    expect(payment.history).to include("Tarifa Pacote de Serviços")
  end

  it "POST BB xlsx persists Pix Recebido Inflow 6300 cents" do
    _account, _organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }

    inflow = bank_account.bank_statements.last.inflows.find_by!(amount_cents: 6300, occurred_on: Date.new(2026, 5, 4))
    expect(inflow.history).to eq("Pix - Recebido — 04/05 17:51 DIEGO OLIVEIRA VIEIRA")
  end

  it "GET /months/2026-05 lists tarifa under Pagamentos as R$ 155,00" do
    _account, _organization, bank_account = open_with_account(name: "Conta Principal")

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }
    get "/months/2026-05"

    expect(response.body).to include("Recebimentos")
    expect(response.body).to include("Pagamentos")
    expect(response.body).to include("11/05/2026")
    expect(response.body).to include("R$ 155,00")
    expect(response.body).to include("Conta Principal")
  end

  it "import error renders as a data-notice error alert" do
    _account, _organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: { bank_account_id: bank_account.id }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Envie a planilha")
  end

  it "POST spreadsheet only persists statement without pdf" do
    _account, organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, spreadsheet: bb_xlsx
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    statements = BankStatement.joins(:month).where(months: { organization_id: organization.id })
    expect(statements.count).to eq(1)
    statement = statements.first
    expect(statement.bank_account_id).to eq(bank_account.id)
    expect(statement.spreadsheet).to be_attached
    expect(statement.spreadsheet.filename.to_s).to eq("extrato-maio-2026.xlsx")
    expect(statement.pdf).not_to be_attached
  end

  it "GET after spreadsheet-only shows Presente Planilha and no Pdf" do
    _account, _organization, bank_account = open_with_account
    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, spreadsheet: bb_xlsx
    }

    get "/months/2026-05"

    account_row = row(response.body, "bank-account", bank_account_id: bank_account.id)
    documents = account_row.at_css('[data-cell="documents"]')
    expect(account_row.text).to include("Presente")
    expect(documents.text).to include("Planilha")
    expect(documents.text).to include("extrato-maio-2026.xlsx")
    expect(documents.text).not_to include("Pdf")
    expect(account_row.at_css('[data-cell="situation"]').text.strip).to eq("Presente")
    expect(response.body).not_to include("Falta o extrato")
  end

  it "POST pdf and spreadsheet shows Pdf then Planilha in Documentos" do
    _account, organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    statement = BankStatement.joins(:month).where(months: { organization_id: organization.id }).first
    expect(statement.pdf).to be_attached
    expect(statement.spreadsheet).to be_attached

    get "/months/2026-05"
    account_row = row(response.body, "bank-account", bank_account_id: bank_account.id)
    lines = account_row.at_css('[data-cell="documents"]').css("p").map { |node| node.text.strip }
    expect(lines).to eq([ "Pdf extrato-maio-2026.pdf", "Planilha extrato-maio-2026.xlsx" ])
    expect(account_row.at_css('[data-cell="situation"]').text.strip).to eq("Presente")
  end

  it "POST pdf only returns 422 Envie a planilha" do
    _account, organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Envie a planilha")
    expect(BankStatement.joins(:month).where(months: { organization_id: organization.id }).count).to eq(0)
  end

  it "POST without files returns 422 Envie a planilha" do
    _account, organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: { bank_account_id: bank_account.id }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Envie a planilha")
    expect(BankStatement.joins(:month).where(months: { organization_id: organization.id }).count).to eq(0)
  end

  it "POST without files opens Incluir extrato on the failing account" do
    _account, organization, bank_account = open_with_account
    other = BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "033")

    post "/months/2026-05/bank_statements", params: { bank_account_id: bank_account.id }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Envie a planilha")
    failing = row(response.body, "bank-account", bank_account_id: bank_account.id)
    other_row = row(response.body, "bank-account", bank_account_id: other.id)
    failing_details = failing.css("details").find { |node| node.at_css("summary")&.text&.strip == "Incluir extrato" }
    other_details = other_row.css("details").find { |node| node.at_css("summary")&.text&.strip == "Incluir extrato" }
    expect(failing_details.has_attribute?("open")).to eq(true)
    expect(other_details.has_attribute?("open")).to eq(false)
  end

  it "POST BB scrambled headers returns 422 Nao foi possivel ler a planilha" do
    _account, organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: scrambled_xlsx
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Não foi possível ler a planilha")
    expect(BankStatement.joins(:month).where(months: { organization_id: organization.id }).count).to eq(0)
  end

  it "POST BB csv persists 18 Inflows and 13 Payments" do
    _account, _organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_csv
    }

    statement = bank_account.bank_statements.last
    expect(statement.inflows.count).to eq(18)
    expect(statement.payments.count).to eq(13)
  end

  it "unauthenticated POST bank_statements responds 302 to /login" do
    expect do
      post "/months/2026-05/bank_statements", params: {
        bank_account_id: 1, pdf: statement_pdf, spreadsheet: bb_xlsx
      }
    end.not_to change(BankStatement, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "POST PagSeguro xlsx persists 64 Inflows and 7 Payments" do
    _account, _organization, bank_account = open_with_account(compe: "290", name: "PagSeguro")

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: pagseguro_pdf, spreadsheet: pagseguro_xlsx
    }

    statement = bank_account.bank_statements.last
    expect(statement.inflows.count).to eq(64)
    expect(statement.payments.count).to eq(7)
  end

  it "POST PagSeguro xlsx persists Pix enviado Payment 151240 cents" do
    _account, _organization, bank_account = open_with_account(compe: "290", name: "PagSeguro")

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: pagseguro_pdf, spreadsheet: pagseguro_xlsx
    }

    payment = bank_account.bank_statements.last.payments.find_by!(amount_cents: 151240)
    expect(payment.occurred_on).to eq(Date.new(2026, 5, 11))
    expect(payment.history).to eq("Pix enviado — VITOR CASTRO FERREIRA")
  end

  it "POST replace drops previous tarifa Payment" do
    _account, _organization, bank_account = open_with_account
    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: one_row_csv
    }

    expect(bank_account.bank_statements.count).to eq(1)
    expect(Payment.where("history LIKE ?", "%Tarifa Pacote de Serviços%")).to be_empty
    expect(bank_account.bank_statements.last.payments.count).to eq(1)
  end

  it "POST Itau COMPE 341 returns 422 Este banco ainda nao tem leitura" do
    _account, organization, bank_account = open_with_account(compe: "341", name: "Itaú")

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Este banco ainda não tem leitura de planilha")
    expect(BankStatement.joins(:month).where(months: { organization_id: organization.id }).count).to eq(0)
  end

  it "POST bank_statements of another organization returns 404" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    foreign = BankAccount.create_for(organization: org_b, name: "Alheia", compe: "001")
    sign_in_as(account, organization: org_a)
    post "/months", params: { year_month: "2026-05" }

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: foreign.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }

    expect(response).to have_http_status(:not_found)
    expect(org_b.months.count).to eq(0)
    expect(BankStatement.count).to eq(0)
  end

  it "POST bank_statements for inactive account returns 404" do
    _account, organization, bank_account = open_with_account
    bank_account.apply_from(active: false)

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }

    expect(response).to have_http_status(:not_found)
    expect(BankStatement.joins(:month).where(months: { organization_id: organization.id }).count).to eq(0)
  end

  it "GET /months/2026-05 after deactivate still lists Payment and omits Falta" do
    _account, _organization, bank_account = open_with_account
    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }
    bank_account.apply_from(active: false)

    get "/months/2026-05"

    expect(response.body).to include("Tarifa Pacote de Serviços")
    expect(response.body).not_to include("Falta")
  end

  it "POST file of 10485761 bytes returns 422 max 10 MB" do
    _account, organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: oversized_pdf, spreadsheet: bb_xlsx
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Cada arquivo pode ter no máximo 10 MB")
    expect(BankStatement.joins(:month).where(months: { organization_id: organization.id }).count).to eq(0)
  end

  it "POST ofx spreadsheet returns 422 Envie a planilha" do
    _account, organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: ofx_file
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Envie a planilha")
    expect(BankStatement.joins(:month).where(months: { organization_id: organization.id }).count).to eq(0)
  end

  it "POST replace without pdf keeps existing pdf" do
    _account, _organization, bank_account = open_with_account
    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, spreadsheet: one_row_csv
    }

    expect(bank_account.bank_statements.count).to eq(1)
    statement = bank_account.bank_statements.last
    expect(statement.pdf.filename.to_s).to eq("extrato-maio-2026.pdf")
    expect(statement.spreadsheet.filename.to_s).to eq("replace.csv")

    get "/months/2026-05"
    documents = row(response.body, "bank-account", bank_account_id: bank_account.id).at_css('[data-cell="documents"]')
    expect(documents.text).to include("Pdf extrato-maio-2026.pdf")
    expect(documents.text).to include("Planilha")
    expect(documents.text).to include("replace.csv")
  end

  it "POST pdf onto spreadsheet-only attaches pdf" do
    _account, _organization, bank_account = open_with_account
    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, spreadsheet: bb_xlsx
    }

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }

    expect(bank_account.bank_statements.last.pdf.filename.to_s).to eq("extrato-maio-2026.pdf")

    get "/months/2026-05"
    documents = row(response.body, "bank-account", bank_account_id: bank_account.id).at_css('[data-cell="documents"]')
    expect(documents.text).to include("Pdf extrato-maio-2026.pdf")
    expect(documents.text).to include("Planilha")
    expect(documents.text).to include("extrato-maio-2026.xlsx")
  end

  it "POST BB row dated 2026-04-01 returns 422 fora de 2026-05" do
    _account, organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_csv_with_april_row
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("A planilha tem movimentação fora de 2026-05")
    expect(BankStatement.joins(:month).where(months: { organization_id: organization.id }).count).to eq(0)
  end

  it "POST zero-row spreadsheet persists Presente" do
    _account, _organization, bank_account = open_with_account

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: zero_row_csv
    }
    get "/months/2026-05"

    expect(bank_account.bank_statements.count).to eq(1)
    expect(response.body).to include("Presente")
  end

  it "month page does not include another organization Payment history" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    account_b = BankAccount.create_for(organization: org_b, name: "Conta B", compe: "001")
    sign_in_as(account, organization: org_b)
    post "/months", params: { year_month: "2026-05" }
    post "/months/2026-05/bank_statements", params: {
      bank_account_id: account_b.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }

    sign_in_as(account, organization: org_a)
    post "/months", params: { year_month: "2026-05" }
    get "/months/2026-05"

    expect(response.body).not_to include("Tarifa Pacote de Serviços")
    expect(response.body).not_to include("DIEGO OLIVEIRA VIEIRA")
  end

  it "GET /months/2026-05 lists Payment dates ascending" do
    _account, _organization, bank_account = open_with_account
    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }
    get "/months/2026-05"

    section = response.body[response.body.index("Pagamentos")..]
    dates = section.scan(/datetime="(\d{4}-\d{2}-\d{2})"/).flatten
    expect(dates.size).to be >= 2
    expect(dates).to eq(dates.sort)
  end

  it "POST replace dissolves Match and returns documents to pool" do
    account, organization, bank_account = open_with_account
    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }
    payment = bank_account.bank_statements.last.payments.find_by!(amount_cents: 15500)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ document.id ]
    }

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: one_row_csv
    }

    expect(Match.count).to eq(0)
    get "/months/2026-05"
    expect(pool_html(response.body)).to include("Padaria Central")
    get "/supporting_documents"
    expect(response.body).not_to include("Casado em 2026-05")
  end

  it "POST bank_statements while closed returns 422 Mes fechado" do
    _account, organization, bank_account = open_with_account
    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }
    month = organization.months.find_by!(year_month: "2026-05")
    existing_id = month.bank_statements.first.id
    month.update!(closed: true)

    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: one_row_csv
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(month.bank_statements.find(existing_id).payments.count).to be > 1
  end

  it "submitter POST bank_statements persists no statement and responds 404" do
    _coord, organization, bank_account = open_with_account
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    expect do
      post "/months/2026-05/bank_statements", params: {
        bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
      }
    end.not_to change(BankStatement, :count)

    expect(response).to have_http_status(:not_found)
  end
end
