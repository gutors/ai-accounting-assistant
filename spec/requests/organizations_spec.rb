require "rails_helper"

RSpec.describe "Organization home", type: :request do
  it "organization home lists standing and pending coordinator emails" do
    account, organization = plant_coordinator(email: "coord@example.com")
    Invite.create!(organization: organization, email: "guest@example.com", kind: :coordinator)
    sign_in_as(account, organization: organization)

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("coord@example.com")
    expect(response.body).to include("guest@example.com")
  end

  it "organization home lists standing submitter email" do
    account, organization = plant_coordinator(email: "coord@example.com")
    plant_submitter(email: "sub@example.com", organization: organization)
    sign_in_as(account, organization: organization)

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("sub@example.com")
  end

  it "organization home lists no pending invite when none exist" do
    account, organization = plant_coordinator(email: "coord@example.com")
    sign_in_as(account, organization: organization)

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("guest@example.com")
    expect(organization.invites).to be_empty
  end

  it "revoke control includes data-turbo-confirm" do
    account, organization = plant_coordinator
    other = Account.create!(email: "other@example.com", google_uid: "uid-other")
    Access.create!(account: other, organization: organization, kind: :coordinator)
    sign_in_as(account, organization: organization)

    get "/"

    expect(response.body).to include("data-turbo-confirm")
  end

  it "home lists organization names when Account has multiple Accesses" do
    account, first = plant_coordinator(email: "coord@example.com", organization_name: "ONG Norte")
    second = Organization.create!(name: "ONG Sul")
    Access.create!(account: account, organization: second, kind: :coordinator)
    sign_in_as(account, organization: first)

    get "/"

    expect(response.body).to include("ONG Norte")
    expect(response.body).to include("ONG Sul")
  end

  it "focused home does not list another organization Access or Invite" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "A")
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    other = Account.create!(email: "only-b@example.com", google_uid: "uid-only-b")
    Access.create!(account: other, organization: org_b, kind: :coordinator)
    Invite.create!(organization: org_b, email: "invite-b@example.com", kind: :coordinator)
    sign_in_as(account, organization: org_a)

    get "/"

    expect(response.body).not_to include("only-b@example.com")
    expect(response.body).not_to include("invite-b@example.com")
  end

  it "organization home links Documentos to /supporting_documents" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Documentos")
    expect(response.body).to include('href="/supporting_documents"')
  end

  it "organization home links Configuracao to /setup" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Configuração")
    expect(response.body).to include('href="/setup"')
  end

  it "organization home includes Meses form posting year_month to /months" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Meses")
    expect(response.body).to include('action="/months"')
    expect(response.body).to include('name="year_month"')
  end

  it "GET / with no Month includes Nenhum mes aberto" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/"

    expect(response.body).to include("Nenhum mês aberto")
  end

  it "GET / links 2026-05 to /months/2026-05" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    get "/"

    expect(response.body).to include("2026-05")
    expect(response.body).to include('href="/months/2026-05"')
  end

  it "submitter home lists organization names when Account has multiple Accesses" do
    account, first = plant_submitter(email: "sub@example.com", organization_name: "ONG Norte")
    second = Organization.create!(name: "ONG Sul")
    Access.create!(account: account, organization: second, kind: :submitter)
    sign_in_as(account, organization: first)

    get "/"

    expect(response.body).to include("ONG Norte")
    expect(response.body).to include("ONG Sul")
  end

  it "submitter home omits close-ritual chrome" do
    account, organization = plant_submitter
    sign_in_as(account, organization: organization)

    get "/"

    expect(response.body).not_to include("Abrir mês")
    expect(response.body).not_to include("Fechar para envio")
    expect(response.body).not_to include("Configuração")
    expect(response.body).not_to include("Convidar coordenador")
  end

  it "home h1 is Meses and an open month row says Aberto" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    Month.open(organization: organization, year_month: "2026-05")

    get "/"

    expect(page_doc(response.body).at_css("h1").text.strip).to eq("Meses")
    month_rows = rows(response.body, "month")
    expect(month_rows.size).to eq(1)
    expect(month_rows.first.at_css('a[href="/months/2026-05"]')).not_to be_nil
    expect(month_rows.first.text).to include("Aberto")
    expect(month_rows.first.text).not_to include("Fechado")
  end

  it "home has a Pessoas h2" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/"

    headings = page_doc(response.body).css("h2").map { |h2| h2.text.strip }
    expect(headings).to include("Pessoas")
  end

  it "closed month row says Fechado" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month = Month.open(organization: organization, year_month: "2026-05")
    month.update!(closed: true)

    get "/"

    month_row = rows(response.body, "month").first
    expect(month_row.at_css('a[href="/months/2026-05"]')).not_to be_nil
    expect(month_row.text).to include("Fechado")
    expect(month_row.text).not_to include("Aberto")
  end

  it "submitter home says Inicio and points to Documentos" do
    account, organization = plant_submitter
    sign_in_as(account, organization: organization)

    get "/"

    expect(page_doc(response.body).at_css("h1").text.strip).to eq("Início")
    expect(response.body).to include("Inclua e acompanhe seus documentos de suporte em")
    expect(page_doc(response.body).at_css('main a[href="/supporting_documents"]')).not_to be_nil
    expect(response.body).not_to include("Meses")
  end
end
