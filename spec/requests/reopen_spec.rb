require "rails_helper"

RSpec.describe "Reopen month", type: :request do
  def signed_closed
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ready_to_close!(organization)
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000, history: "Pix enviado")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
    post "/months/2026-05/close"
    [ account, organization, month.reload, statement ]
  end

  it "POST reopen persists open 302 and does not write" do
    _account, _organization, month, _statement = signed_closed
    calls = writer.calls.size

    post "/months/2026-05/reopen"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(month.reload.closed?).to eq(false)
    expect(writer.calls.size).to eq(calls)
  end

  it "GET after reopen includes Fechar para envio and omits Mes fechado" do
    _account, _organization, _month, _statement = signed_closed
    post "/months/2026-05/reopen"

    get "/months/2026-05"

    expect(response.body).to include("Fechar para envio")
    expect(response.body).to include("Enviar extrato")
    expect(response.body).not_to include("Mês fechado")
  end

  it "reopen keeps matches payments statements and month_folder_id" do
    _account, organization, month, statement = signed_closed
    folder_id = month.month_folder_id
    match_id = month.matches.first.id
    payment_id = statement.payments.first.id
    statement_id = statement.id

    post "/months/2026-05/reopen"

    month.reload
    expect(month.closed?).to eq(false)
    expect(month.month_folder_id).to eq(folder_id)
    expect(Match.exists?(match_id)).to eq(true)
    expect(Payment.exists?(payment_id)).to eq(true)
    expect(BankStatement.exists?(statement_id)).to eq(true)
    expect(organization.months.find_by!(year_month: "2026-05").matches.count).to eq(1)
  end

  it "POST reopen while open returns 422 Mes aberto" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, _statement = plant_month(organization)

    post "/months/2026-05/reopen"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês aberto")
    expect(month.reload.closed?).to eq(false)
  end

  it "unauthenticated POST reopen responds 302 to /login" do
    _account, organization = plant_coordinator
    ready_to_close!(organization)
    month, _statement = plant_month(organization)
    month.close_for_send

    post "/months/2026-05/reopen"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(month.reload.closed?).to eq(true)
  end

  it "POST reopen of another organization month returns 404" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    ready_to_close!(org_b)
    month_b, _statement = plant_month(org_b)
    month_b.close_for_send
    sign_in_as(account, organization: org_a)

    post "/months/2026-05/reopen"

    expect(response).to have_http_status(:not_found)
    expect(month_b.reload.closed?).to eq(true)
  end

  it "POST reopen of never-opened 2026-04 returns 404" do
    _account, _organization, _month, _statement = signed_closed

    post "/months/2026-04/reopen"

    expect(response).to have_http_status(:not_found)
  end

  it "submitter POST reopen leaves month closed and responds 404" do
    _coord, organization, month, _statement = signed_closed
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    post "/months/2026-05/reopen"

    expect(month.reload.closed?).to eq(true)
    expect(response).to have_http_status(:not_found)
  end

  it "POST reopen after unmatched Padaria close keeps month_id and shows Devolver" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ready_to_close!(organization)
    month, _statement = plant_month(organization)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    post "/months/2026-05/close", params: { supporting_document_ids: [ document.id ] }
    calls = writer.calls.size

    post "/months/2026-05/reopen"

    expect(month.reload.closed?).to eq(false)
    expect(writer.calls.size).to eq(calls)
    document.reload
    expect(document.month_id).to eq(month.id)
    expect(document.match_id).to be_nil

    get "/months/2026-05"
    expect(response.body).to include("Fechar para envio")
    expect(response.body).to include('data-turbo-confirm="Fechar o mês para envio?"')
    expect(pool_html(response.body)).to include("Devolver")
    expect(pool_html(response.body)).to include("Padaria Central")
    expect(response.body).not_to include("Restaurar pasta")
    expect(response.body).not_to include("Mês fechado")
  end
end
