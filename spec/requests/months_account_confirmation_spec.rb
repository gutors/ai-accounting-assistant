require "rails_helper"

# Account confirmation and the never-sent month discard. Split out of months_spec.rb, which had
# grown past the repo file-token limit; the examples are unchanged apart from the toast copy.
RSpec.describe "Months account confirmation", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  def confirm_section(body)
    page_doc(body).css("section").find { |section| section.at_css("h2")&.text&.strip == "Confirmar contas para fechamento" }
  end

  it "unconfirmed GET hides movements and shows confirm step" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    headings = month_h2s(response.body)
    expect(headings).to include("Contas bancárias")
    expect(headings).to include("Confirmar contas para fechamento")
    expect(headings.index("Contas bancárias")).to be < headings.index("Confirmar contas para fechamento")
    form = page_doc(response.body).at_css('form[action="/months/2026-05/account_confirmation"]')
    expect(form).to be_present
    submit = form.at_css('input[type="submit"][value="Iniciar fechamento"]')
    expect(submit).to be_present
    expect(submit["disabled"]).to eq("disabled")
    expect(error_notice_text(response.body)).to eq("Inclua o extrato planilha de pelo menos uma conta bancária.")
    expect(response.body).to include("Insira os extratos das contas bancárias com as quais deseja realizar o fechamento.")
    expect(headings).not_to include("Recebimentos")
    expect(headings).not_to include("Pagamentos")
    expect(headings).not_to include("Documentos sem casamento")
    expect(rows(response.body, "inflow")).to be_empty
    expect(rows(response.body, "payment")).to be_empty
    expect(rows(response.body, "pool-document")).to be_empty
    expect(response.body).not_to include("pagamento com documento faltante")
  end

  it "unconfirmed confirm step lists Alfa then Principal with Falta in margem" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "033")
    principal = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }
    post "/months/2026-05/bank_statements", params: { bank_account_id: principal.id, spreadsheet: bb_xlsx }

    get "/months/2026-05"

    bank_names = rows(response.body, "bank-account").map { |row| row.element_children[1].text.strip }
    expect(bank_names).to eq([ "Conta Alfa", "Conta Principal" ])
    section = confirm_section(response.body)
    expect(section).to be_present
    head = section.at_css(".ledger-head.ledger-confirm")
    expect(head.element_children.map { |node| node.text.strip }).to eq([ "Nome", "Situação" ])
    confirm_rows = section.css("li.ledger-confirm")
    expect(confirm_rows.map { |row| row.element_children.map { |cell| cell.text.strip } }).to eq(
      [ [ "Conta Alfa", "Falta" ], [ "Conta Principal", "Presente" ] ]
    )
    confirm_names = section.css("li.ledger-confirm p.font-medium").map { |node| node.text.strip }
    expect(confirm_names).to eq([ "Conta Alfa", "Conta Principal" ])
    expect(section.text).to include("Falta")
    expect(section.text).to include("Presente")
    alfa_row = section.css("li.ledger-confirm").find { |row| row.text.include?("Conta Alfa") }
    expect(alfa_row.at_css(".text-margem").text.strip).to eq("Falta")
    submit = section.at_css('input[type="submit"][value="Iniciar fechamento"]')
    expect(submit).to be_present
    expect(submit["disabled"]).to be_nil
    expect(response.body).not_to include("Inclua o extrato planilha de pelo menos uma conta bancária.")
  end

  it "unconfirmed GET with no active accounts still shows confirm step" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).to include("Nenhuma conta bancária ativa")
    headings = month_h2s(response.body)
    expect(headings).to include("Confirmar contas para fechamento")
    submit = page_doc(response.body).at_css('input[type="submit"][value="Iniciar fechamento"]')
    expect(submit).to be_present
    expect(submit["disabled"]).to eq("disabled")
    expect(error_notice_text(response.body)).to eq("Inclua o extrato planilha de pelo menos uma conta bancária.")
    expect(headings).not_to include("Recebimentos")
    expect(headings).not_to include("Pagamentos")
    expect(headings).not_to include("Documentos sem casamento")
  end

  it "unconfirmed GET with tarifa uses insert-statements summary not missing-document count" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }
    post "/months/2026-05/bank_statements", params: { bank_account_id: bank_account.id, spreadsheet: bb_xlsx }

    get "/months/2026-05"

    expect(response.body).to include("Insira os extratos das contas bancárias com as quais deseja realizar o fechamento.")
    expect(response.body).not_to include("1 pagamento com documento faltante")
    expect(rows(response.body, "payment")).to be_empty
  end

  it "POST account_confirmation reveals movements and Pronto toast" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }
    post "/months/2026-05/bank_statements", params: { bank_account_id: bank_account.id, spreadsheet: bb_xlsx }
    statement = bank_account.bank_statements.last
    statement.payments.where.not(amount_cents: 15500).find_each { |payment| payment.mark_document_exception("bank_fee") }

    post "/months/2026-05/account_confirmation"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(organization.months.find_by!(year_month: "2026-05").accounts_confirmed).to eq(true)

    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_message(response.body)).to eq("Contas de maio de 2026 confirmadas.")
    headings = month_h2s(response.body)
    expect(month_fold_summaries(response.body)).to eq([ "Pagamentos", "Documentos sem casamento", "Recebimentos" ])
    expect(headings).not_to include("Recebimentos")
    expect(headings).not_to include("Pagamentos")
    expect(headings).not_to include("Documentos sem casamento")
    expect(headings).not_to include("Confirmar contas para fechamento")
    summary = page_doc(response.body).at_css("p.mt-6 .text-margem")
    expect(summary.text).to include("1 pagamento com documento faltante")
    payment_row = rows(response.body, "payment").find { |row| row.text.include?("R$ 155,00") }
    expect(payment_row).to be_present
  end

  it "POST account_confirmation with mixed Falta keeps Alfa Falta and lists Principal movements" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "033")
    principal = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }
    post "/months/2026-05/bank_statements", params: { bank_account_id: principal.id, spreadsheet: bb_xlsx }

    post "/months/2026-05/account_confirmation"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(organization.months.find_by!(year_month: "2026-05").accounts_confirmed).to eq(true)
    get "/months/2026-05"
    expect(month_fold_summaries(response.body)).to include("Pagamentos")
    expect(month_h2s(response.body)).not_to include("Pagamentos")
    expect(month_h2s(response.body)).not_to include("Confirmar contas para fechamento")
    expect(response.body).to include("Conta Principal")
    expect(rows(response.body, "payment")).not_to be_empty
    expect(response.body).to include("Falta o extrato de 1 conta ativa")
    alfa_row = rows(response.body, "bank-account").find { |row| row.text.include?("Conta Alfa") }
    expect(alfa_row.at_css('[data-cell="situation"]').text.strip).to eq("Falta")
  end

  it "POST account_confirmation without spreadsheet returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }

    post "/months/2026-05/account_confirmation"

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Inclua o extrato planilha de pelo menos uma conta bancária.")
    expect(organization.months.find_by!(year_month: "2026-05").accounts_confirmed).to eq(false)
  end

  it "second POST account_confirmation is idempotent" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }
    post "/months/2026-05/bank_statements", params: { bank_account_id: bank_account.id, spreadsheet: bb_xlsx }
    post "/months/2026-05/account_confirmation"

    post "/months/2026-05/account_confirmation"

    expect(response).to have_http_status(:found)
    month = organization.months.find_by!(year_month: "2026-05")
    expect(month.accounts_confirmed).to eq(true)
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
    follow_redirect!
    expect(month_fold_summaries(response.body)).to eq([ "Pagamentos", "Documentos sem casamento", "Recebimentos" ])
    expect(month_h2s(response.body)).not_to include("Recebimentos")
    expect(toast_message(response.body)).to eq("Contas de maio de 2026 confirmadas.")
  end

  it "closed GET shows movements even when accounts_confirmed is false" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization, accounts_confirmed: false)
    plant_payment(statement, 22000)
    organization.months.find_by!(year_month: "2026-05").update_columns(closed: true)

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    stamp = page_doc(response.body).at_css('[data-stamp="closed"]')
    expect(stamp.text.strip).to eq("Mês fechado")
    expect(month_h2s(response.body)).not_to include("Confirmar contas para fechamento")
    expect(rows(response.body, "payment")).not_to be_empty
  end

  it "POST account_confirmation on closed month returns 422 Mes fechado" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization, accounts_confirmed: false)
    plant_payment(statement, 22000)
    month = organization.months.find_by!(year_month: "2026-05")
    month.update_columns(closed: true)

    post "/months/2026-05/account_confirmation"

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Mês fechado")
    expect(month.reload.accounts_confirmed).to eq(false)
  end

  it "DELETE never-sent empty month redirects home and frees year_month" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    delete "/months/2026-05"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    expect(organization.months.where(year_month: "2026-05").count).to eq(0)

    follow_redirect!
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_message(response.body)).to eq("Fechamento de maio de 2026 excluído.")
    expect(response.body).to include("Nenhum mês aberto")

    post "/months", params: { year_month: "2026-05" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end

  it "DELETE never-sent month destroys statements matches and nullifies documents" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, statement = plant_month(organization, accounts_confirmed: true)
    attach_statement_files(statement)
    payment = plant_payment(statement, 22000)
    plant_inflow(statement, 6300)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
    expect(document.reload.month_id).to eq(month.id)

    expect(PackageArchiveWriter).not_to receive(:current)
    delete "/months/2026-05"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    expect(organization.months.where(year_month: "2026-05")).to be_empty
    expect(BankStatement.where(id: statement.id)).to be_empty
    expect(Payment.where(id: payment.id)).to be_empty
    expect(Inflow.where(bank_statement_id: statement.id)).to be_empty
    expect(Match.where(month_id: month.id)).to be_empty
    expect(document.reload.month_id).to be_nil
  end

  it "DELETE closed month returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month = Month.open(organization: organization, year_month: "2026-05")
    month.update!(closed: true)

    delete "/months/2026-05"

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Só é possível excluir um fechamento aberto que nunca foi enviado.")
    expect(month.reload).to be_closed
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end

  it "DELETE reopened month returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month = Month.open(organization: organization, year_month: "2026-05")
    month.update!(closed: false, month_folder_id: "drive-folder")

    delete "/months/2026-05"

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Só é possível excluir um fechamento aberto que nunca foi enviado.")
    expect(organization.months.find_by!(year_month: "2026-05").month_folder_id).to eq("drive-folder")
  end

  it "DELETE invalid or missing month returns 404" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    Month.open(organization: organization, year_month: "2026-04")

    delete "/months/2026-13"

    expect(response).to have_http_status(:not_found)
    expect(organization.months.count).to eq(1)

    delete "/months/2026-05"

    expect(response).to have_http_status(:not_found)
    expect(organization.months.where(year_month: "2026-04").count).to eq(1)
  end

  it "submitter DELETE month returns 404" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    Month.open(organization: organization, year_month: "2026-05")
    sign_in_as(submitter, organization: organization)

    delete "/months/2026-05"

    expect(response).to have_http_status(:not_found)
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end
end
