require "rails_helper"

RSpec.describe "Return unmatched-in-package document", type: :request do
  def signed_unmatched_padaria
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ready_to_close!(organization)
    month, _statement = plant_month(organization)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    post "/months/2026-05/close", params: { supporting_document_ids: [ document.id ] }
    post "/months/2026-05/reopen"
    [ account, organization, month.reload, document.reload ]
  end

  it "POST return Padaria while open clears month_id and omits Devolver" do
    _account, _organization, month, document = signed_unmatched_padaria

    post "/months/2026-05/supporting_documents/#{document.id}/return"

    expect(document.reload.month_id).to be_nil
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    get "/months/2026-05"
    expect(pool_html(response.body)).to include("Padaria Central")
    expect(pool_html(response.body)).not_to include("Devolver")
  end

  it "POST return while closed returns 422 Mes fechado" do
    _account, _organization, month, document = signed_unmatched_padaria
    post "/months/2026-05/close"

    post "/months/2026-05/supporting_documents/#{document.id}/return"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(document.reload.month_id).to eq(month.id)
  end

  it "unauthenticated POST return responds 302 to /login" do
    account, organization = plant_coordinator
    ready_to_close!(organization)
    month, _statement = plant_month(organization)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    month.close_for_send(supporting_documents: [ document ])
    month.reopen

    post "/months/2026-05/supporting_documents/#{document.id}/return"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(document.reload.month_id).to eq(month.id)
  end

  it "submitter POST return returns 404" do
    _account, organization, month, document = signed_unmatched_padaria
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    post "/months/2026-05/supporting_documents/#{document.id}/return"

    expect(response).to have_http_status(:not_found)
    expect(document.reload.month_id).to eq(month.id)
  end

  it "POST return of a matched document returns 404" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 15500)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    post "/months/2026-05/supporting_documents/#{document.id}/return"

    expect(response).to have_http_status(:not_found)
    expect(document.reload.match_id).to be_present
    expect(document.month_id).to eq(month.id)
  end

  it "POST return of a no-month document returns 404" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    post "/months/2026-05/supporting_documents/#{document.id}/return"

    expect(response).to have_http_status(:not_found)
    expect(document.reload.month_id).to be_nil
  end

  it "POST return of another organization document returns 404" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    ready_to_close!(org_b)
    month_b, _statement = plant_month(org_b)
    document = plant_recibo(org_b, account, payee: "Padaria Central", amount: "155,00")
    month_b.close_for_send(supporting_documents: [ document ])
    month_b.reopen
    sign_in_as(account, organization: org_a)
    plant_month(org_a)

    post "/months/2026-05/supporting_documents/#{document.id}/return"

    expect(response).to have_http_status(:not_found)
    expect(document.reload.month_id).to eq(month_b.id)
  end
end
