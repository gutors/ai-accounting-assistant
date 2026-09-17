require "rails_helper"

RSpec.describe "Months", type: :request do
  it "unauthenticated GET /months/2026-05 responds 302 to /login" do
    get "/months/2026-05"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "GET /months/2026-05 without focus responds 302 to /login" do
    account, organization = plant_coordinator(email: "coord@example.com")
    other = Account.create!(email: "other@example.com", google_uid: "uid-other")
    Access.create!(account: other, organization: organization, kind: :coordinator)
    sign_in_as(account, organization: organization)
    Access.where(account: account).delete_all

    get "/months/2026-05"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "POST /months 2026-05 persists Month and redirects" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    post "/months", params: { year_month: "2026-05" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end

  it "POST /months 2026-05 a second time does not duplicate" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    post "/months", params: { year_month: "2026-05" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end

  it "GET /months/2026-05 responds 200 with pt-BR and 2026-05" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('lang="pt-BR"')
    expect(response.body).to include("2026-05")
  end

  it "GET /months/2026-05 with zero active accounts includes Nenhuma conta bancaria ativa" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).to include("Nenhuma conta bancária ativa")
  end

  it "GET /months/2026-05 includes active account name and Falta" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).to include("Conta Principal")
    expect(response.body).to include("Falta")
  end

  it "GET /months/2026-05 includes coordinates on the account card" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001", coordinates: "ag 1234")
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).to include("ag 1234")
  end

  it "POST /months 2026-13 returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    expect do
      post "/months", params: { year_month: "2026-13" }
    end.not_to change(Month, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "GET /months/2026-13 responds 404" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/months/2026-13"

    expect(response).to have_http_status(:not_found)
  end

  it "GET /months/2026-04 when never opened responds 404" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/months/2026-04"

    expect(response).to have_http_status(:not_found)
  end

  it "unauthenticated POST /months responds 302 to /login" do
    expect do
      post "/months", params: { year_month: "2026-05" }
    end.not_to change(Month, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "month page does not include another organization bank account names" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    BankAccount.create_for(organization: org_a, name: "Conta Alfa", compe: "001")
    BankAccount.create_for(organization: org_b, name: "Conta Beta", compe: "001")
    sign_in_as(account, organization: org_a)
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).to include("Conta Alfa")
    expect(response.body).not_to include("Conta Beta")
  end

  it "DELETE /months/2026-05 returns 404 and keeps the Month" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    delete "/months/2026-05"

    expect(response).to have_http_status(:not_found)
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end

  it "GET /months/2026-05 unmatched payment includes Documento faltante" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization)
    plant_payment(statement, 22000)

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Documento faltante")
    expect(response.body).to include("R$ 220,00")
  end

  it "GET /months/2026-05 with zero Payments does not include Documento faltante" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).not_to include("Documento faltante")
  end

  it "GET /months/2026-05 includes Documentos sem casamento" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).to include("Documentos sem casamento")
  end

  it "GET /months/2026-05 with no unmatched documents includes Nenhum documento sem casamento" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).to include("Nenhum documento sem casamento")
  end

  it "GET /months/2026-05 pool includes unmatched Padaria Central" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization)
    plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/months/2026-05"

    expect(pool_html(response.body)).to include("Padaria Central")
  end

  it "month unmatched pool does not include another organization payee" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    plant_recibo(org_b, account, payee: "Only Org B", amount: "155,00")
    sign_in_as(account, organization: org_a)
    plant_month(org_a)

    get "/months/2026-05"

    expect(response.body).not_to include("Only Org B")
  end

  it "GET /months/2026-05 Recebimentos does not include Documento faltante" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization)
    plant_inflow(statement, 6300)
    plant_payment(statement, 22000)

    get "/months/2026-05"

    expect(recebimentos_html(response.body)).not_to include("Documento faltante")
    expect(recebimentos_html(response.body)).to include("R$ 63,00")
  end

  it "GET /months/2026-05 with every payment resolved omits Documento faltante" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, statement = plant_month(organization)
    matched = plant_payment(statement, 22000)
    excepted = plant_payment(statement, 10000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ matched ], supporting_documents: [ document ])
    excepted.mark_document_exception("bank_fee")

    get "/months/2026-05"

    expect(response.body).not_to include("Documento faltante")
  end
end
