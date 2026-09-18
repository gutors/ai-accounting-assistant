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

  it "POST kind doacao returns 422 Informe um tipo de excecao permitido" do
    _account, _organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { kind: "doacao" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('<p class="mb-6">Informe um tipo de exceção permitido</p>')
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

  it "POST exception while closed returns 422 Mes fechado" do
    _account, _organization, month, statement = signed_month
    payment = plant_payment(statement, 22000)
    month.update!(closed: true)

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { kind: "bank_fee" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(payment.reload.document_exception_kind).to be_nil
  end

  it "DELETE exception while closed returns 422 Mes fechado" do
    _account, _organization, month, statement = signed_month
    payment = plant_payment(statement, 22000)
    payment.mark_document_exception("bank_fee")
    month.update!(closed: true)

    delete "/months/2026-05/payments/#{payment.id}/document_exception"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(payment.reload.document_exception_kind).to eq("bank_fee")
  end

  it "submitter POST document_exception persists no mark and responds 404" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { kind: "bank_fee" }

    expect(response).to have_http_status(:not_found)
    expect(payment.reload.document_exception_kind).to be_nil
  end

  it "POST extra_exception_kind_id Doacao persists and redirects" do
    _account, organization, _month, statement = signed_month
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    payment = plant_payment(statement, 22000)

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { extra_exception_kind_id: kind.id }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(payment.reload.extra_exception_kind_id).to eq(kind.id)
    expect(payment.document_exception_kind).to be_nil

    get "/months/2026-05"
    expect(response.body).to include("Doação")
    expect(response.body).not_to include("Documento faltante")
  end

  it "DELETE extra Doacao returns Documento faltante" do
    _account, organization, _month, statement = signed_month
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    payment = plant_payment(statement, 22000)
    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { extra_exception_kind_id: kind.id }

    delete "/months/2026-05/payments/#{payment.id}/document_exception"

    expect(response).to have_http_status(:found)
    expect(payment.reload.extra_exception_kind_id).to be_nil
    get "/months/2026-05"
    row = response.body[%r{<li class="mb-2">.*?</li>}m]
    status = row.split("<form").first
    expect(status).to include("Documento faltante")
    expect(status).not_to include("Doação")
  end

  it "POST deactivated extra_exception_kind_id returns 422 Informe um tipo de excecao permitido" do
    _account, organization, _month, statement = signed_month
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    kind.apply_active(false)
    payment = plant_payment(statement, 22000)

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { extra_exception_kind_id: kind.id }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Informe um tipo de exceção permitido")
    expect(payment.reload.extra_exception_kind_id).to be_nil
  end

  it "POST kind bank_fee and extra_exception_kind_id returns 422" do
    _account, organization, _month, statement = signed_month
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    payment = plant_payment(statement, 22000)

    post "/months/2026-05/payments/#{payment.id}/document_exception",
      params: { kind: "bank_fee", extra_exception_kind_id: kind.id }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Informe um tipo de exceção permitido")
    expect(payment.reload.document_exception_kind).to be_nil
    expect(payment.extra_exception_kind_id).to be_nil
  end

  it "POST extra_exception_kind_id of another organization returns 404" do
    _account, organization, _month, statement = signed_month
    other = Organization.create!(name: "B")
    foreign = ExtraExceptionKind.create_for(organization: other, name: "Doação")
    payment = plant_payment(statement, 22000)

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { extra_exception_kind_id: foreign.id }

    expect(response).to have_http_status(:not_found)
    expect(payment.reload.extra_exception_kind_id).to be_nil
  end

  it "POST extra_exception_kind_id on matched payment returns 422 Desfaca o casamento" do
    account, organization, _month, statement = signed_month
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ document.id ]
    }

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { extra_exception_kind_id: kind.id }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Desfaça o casamento antes de marcar a exceção")
    expect(Match.count).to eq(1)
    expect(payment.reload.extra_exception_kind_id).to be_nil
  end

  it "POST bank_fee replaces extra Doacao" do
    _account, organization, _month, statement = signed_month
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    payment = plant_payment(statement, 22000)
    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { extra_exception_kind_id: kind.id }

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { kind: "bank_fee" }

    expect(payment.reload.document_exception_kind).to eq("bank_fee")
    expect(payment.extra_exception_kind_id).to be_nil
    get "/months/2026-05"
    expect(response.body).to include("Tarifa bancária")
    expect(response.body).not_to include("Doação")
  end

  it "POST extra_exception_kind_id while closed returns 422 Mes fechado" do
    _account, organization, month, statement = signed_month
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    payment = plant_payment(statement, 22000)
    month.update!(closed: true)

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { extra_exception_kind_id: kind.id }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(payment.reload.extra_exception_kind_id).to be_nil
  end

  it "DELETE extra Doacao while closed returns 422 Mes fechado" do
    _account, organization, month, statement = signed_month
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    payment = plant_payment(statement, 22000)
    payment.mark_document_exception(extra_exception_kind_id: kind.id)
    month.update!(closed: true)

    delete "/months/2026-05/payments/#{payment.id}/document_exception"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(payment.reload.extra_exception_kind_id).to eq(kind.id)
  end

  it "submitter POST extra_exception_kind_id persists no mark and responds 404" do
    account, organization, _month, statement = signed_month
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    payment = plant_payment(statement, 22000)
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { extra_exception_kind_id: kind.id }

    expect(response).to have_http_status(:not_found)
    expect(payment.reload.extra_exception_kind_id).to be_nil
  end
end
