require "rails_helper"

RSpec.describe "Document exceptions", type: :request do
  def signed_month
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, statement = plant_month(organization)
    [ account, organization, month, statement ]
  end

  it "POST bank_fee persists Tarifa bancaria and redirects" do
    _account, _organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { kind: "bank_fee" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(payment.reload.document_exception_kind).to eq("bank_fee")

    get "/months/2026-05"
    expect(response.body).to include("Tarifa bancária")
    expect(response.body).not_to include("Documento faltante")
  end

  it "POST accountant_fee persists Honorario do contador" do
    _account, _organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { kind: "accountant_fee" }

    get "/months/2026-05"
    expect(response.body).to include("Honorário do contador")
    expect(response.body).not_to include("Documento faltante")
  end

  it "DELETE bank_fee returns Documento faltante" do
    _account, _organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { kind: "bank_fee" }

    delete "/months/2026-05/payments/#{payment.id}/document_exception"

    expect(response).to have_http_status(:found)
    expect(payment.reload.document_exception_kind).to be_nil
    get "/months/2026-05"
    expect(response.body).to include("Documento faltante")
    expect(response.body).not_to include("Tarifa bancária")
  end

  it "POST kind doacao returns 422 Informe se e tarifa bancaria ou honorario do contador" do
    _account, _organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { kind: "doacao" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('<p class="mb-6">Informe se é tarifa bancária ou honorário do contador</p>')
    expect(payment.reload.document_exception_kind).to be_nil
  end

  it "POST exception on matched payment returns 422 Desfaca o casamento" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ document.id ]
    }

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { kind: "bank_fee" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Desfaça o casamento antes de marcar a exceção")
    expect(Match.count).to eq(1)
    expect(payment.reload.document_exception_kind).to be_nil
  end

  it "unauthenticated POST document_exception responds 302 to /login" do
    _account, organization = plant_coordinator
    _month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { kind: "bank_fee" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(payment.reload.document_exception_kind).to be_nil
  end

  it "unauthenticated DELETE document_exception responds 302 to /login and keeps the mark" do
    _account, organization = plant_coordinator
    _month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    payment.mark_document_exception("bank_fee")

    delete "/months/2026-05/payments/#{payment.id}/document_exception"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(payment.reload.document_exception_kind).to eq("bank_fee")
  end

  it "DELETE document_exception of another organization returns 404" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    _month_b, statement_b = plant_month(org_b)
    foreign = plant_payment(statement_b, 22000)
    foreign.mark_document_exception("bank_fee")
    sign_in_as(account, organization: org_a)
    plant_month(org_a)

    delete "/months/2026-05/payments/#{foreign.id}/document_exception"

    expect(response).to have_http_status(:not_found)
    expect(foreign.reload.document_exception_kind).to eq("bank_fee")
  end

  it "POST exception for payment of 2026-04 on 2026-05 returns 404" do
    _account, organization, _month, _statement = signed_month
    _april, april_statement = plant_month(organization, year_month: "2026-04")
    april_payment = plant_payment(april_statement, 22000)

    post "/months/2026-05/payments/#{april_payment.id}/document_exception", params: { kind: "bank_fee" }

    expect(response).to have_http_status(:not_found)
    expect(april_payment.reload.document_exception_kind).to be_nil
  end
end
