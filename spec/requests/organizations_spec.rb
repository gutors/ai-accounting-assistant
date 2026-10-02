require "rails_helper"

RSpec.describe "Organization home", type: :request do
  include ActiveSupport::Testing::TimeHelpers

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
    second = create_organization!(name: "ONG Sul")
    Access.create!(account: account, organization: second, kind: :coordinator)
    sign_in_as(account, organization: first)

    get "/"

    expect(response.body).to include("ONG Norte")
    expect(response.body).to include("ONG Sul")
  end

  it "focused home does not list another organization Access or Invite" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
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

  it "GET / picker lists 25 months from 2025-10 to 2027-10" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    travel_to Date.new(2026, 10, 1) do
      get "/"
    end

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Nenhum mês aberto")
    expect(response.body).not_to include('input type="month"')
    doc = page_doc(response.body)
    expect(doc.at_css('input[type="month"][name="year_month"]')).to be_nil
    expect(doc.css("select#year_month").size).to eq(1)
    select = doc.at_css("select#year_month")
    expect(select["name"]).to eq("year_month")
    options = select.css("option")
    expect(options.map { |option| option["value"] }).to eq(
      (0..24).map { |offset| Date.new(2025, 10, 1).next_month(offset).strftime("%Y-%m") }
    )
    selected = select.at_css("option[selected]")
    expect(selected["value"]).to eq("2026-09")
    expect(selected.text.strip).to eq("setembro de 2026")
    expect(options.first.text.strip).to eq("outubro de 2025")
    expect(options.last.text.strip).to eq("outubro de 2027")
    expect(doc.at_css('label[for="year_month"]').text.strip).to eq("Mês")
    open_form = doc.css("form").find { |form| form.at_css('input[type="submit"][value="Abrir mês"]') }
    expect(open_form).not_to be_nil
    expect(open_form["action"]).to eq("/months")
    expect(open_form.at_css("select#year_month")).to eq(select)
  end

  it "GET / picker in January starts 2025-01 ends 2027-01" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    travel_to Date.new(2026, 1, 15) do
      get "/"
    end

    select = page_doc(response.body).at_css("select#year_month")
    values = select.css("option").map { |option| option["value"] }
    expect(values.first).to eq("2025-01")
    expect(values.last).to eq("2027-01")
    expect(select.at_css("option[selected]")["value"]).to eq("2025-12")
  end

  it "GET / lists opened 2026-05 and keeps it in the picker" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    Month.open(organization: organization, year_month: "2026-05")

    travel_to Date.new(2026, 10, 1) do
      get "/"
    end

    month_row = rows(response.body, "month").first
    link = month_row.at_css('a[href="/months/2026-05"]')
    expect(link).not_to be_nil
    expect(link.text).to include("2026-05")
    values = page_doc(response.body).css("select#year_month option").map { |option| option["value"] }
    expect(values).to include("2026-05")
  end

  it "submitter home has no year_month picker" do
    account, organization = plant_submitter
    sign_in_as(account, organization: organization)

    get "/"

    expect(page_doc(response.body).at_css("select#year_month")).to be_nil
    expect(response.body).not_to include("Abrir mês")
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
    second = create_organization!(name: "ONG Sul")
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

  it "GET / does not deliver mail for an already pending Invite" do
    account, organization = plant_coordinator
    Invite.create!(organization: organization, email: "guest@example.com", kind: :coordinator)
    sign_in_as(account, organization: organization)
    ActionMailer::Base.deliveries.clear

    expect { get "/" }.not_to change { ActionMailer::Base.deliveries.size }
  end

  it "submitter home omits invite resend" do
    account, organization = plant_submitter
    sign_in_as(account, organization: organization)

    get "/"

    expect(page_doc(response.body).at_css("h1").text.strip).to eq("Início")
    expect(response.body).not_to include("Reenviar e-mail")
    expect(response.body).not_to include("O convite foi gravado, mas o e-mail não saiu.")
  end

  it "principal coordinator is first and sees Revogar on peer coordinator and submitter rows" do
    zoe, organization = plant_home_people
    sign_in_as(zoe, organization: organization)

    get "/"

    emails = coordinator_emails_on_home
    expect(emails).to eq([ "zoe@exemplo.org", "ana@exemplo.org" ])
    expect(revogar_on_coordinator_row("zoe@exemplo.org")).to be_nil
    ana_revoke = revogar_on_coordinator_row("ana@exemplo.org")
    expect(ana_revoke).not_to be_nil
    expect(ana_revoke.ancestors("form").first["data-turbo-confirm"]).to eq("Revogar o acesso deste coordenador?")
    submitter_revoke = revogar_on_submitter_row("submitter@exemplo.org")
    expect(submitter_revoke.ancestors("form").first["data-turbo-confirm"]).to eq("Revogar o acesso deste submitter?")
    expect(response.body).to include("Convidar coordenador")
    expect(response.body).to include("Convidar submitter")
    expect(response.body).not_to include("coordenador principal")
  end

  it "peer coordinator does not see Revogar on coordinator rows and still revokes submitters" do
    _zoe, organization = plant_home_people
    ana = Account.find_by!(email: "ana@exemplo.org")
    sign_in_as(ana, organization: organization)

    get "/"

    expect(coordinator_emails_on_home).to eq([ "zoe@exemplo.org", "ana@exemplo.org" ])
    expect(revogar_on_coordinator_row("zoe@exemplo.org")).to be_nil
    expect(revogar_on_coordinator_row("ana@exemplo.org")).to be_nil
    submitter_revoke = revogar_on_submitter_row("submitter@exemplo.org")
    expect(submitter_revoke).not_to be_nil
    expect(submitter_revoke.ancestors("form").first["data-turbo-confirm"]).to eq("Revogar o acesso deste submitter?")
    expect(response.body).to include("Convidar coordenador")
    expect(response.body).to include("Convidar submitter")
  end

  it "submitter home omits Revogar and Convidar coordenador" do
    _zoe, organization = plant_home_people
    submitter = Account.find_by!(email: "submitter@exemplo.org")
    sign_in_as(submitter, organization: organization)

    get "/"

    expect(page_doc(response.body).at_css("h1").text.strip).to eq("Início")
    expect(response.body).not_to include("Revogar")
    expect(response.body).not_to include("Convidar coordenador")
  end

  it "after invite accept the first home coordinator row stays the principal" do
    organization = Organization.register_coordinator(name: "ONG Norte", email: "coordenador@exemplo.org")
    principal = Account.find_by!(email: "coordenador@exemplo.org")
    principal.update!(google_uid: "uid-coord")
    invite = Invite.create!(organization: organization, email: "ana@exemplo.org", kind: :coordinator)
    ana = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")
    invite.accept!(ana)
    sign_in_as(principal, organization: organization)

    get "/"

    expect(coordinator_emails_on_home.first).to eq("coordenador@exemplo.org")
  end

  def plant_home_people
    zoe, organization = plant_coordinator(email: "zoe@exemplo.org", organization_name: "ONG Norte", google_uid: "uid-zoe")
    ana = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")
    Access.create!(account: ana, organization: organization, kind: :coordinator)
    plant_submitter(email: "submitter@exemplo.org", organization: organization)
    [ zoe, organization ]
  end

  def coordinator_emails_on_home
    heading = page_doc(response.body).css("h3").find { |node| node.text.strip == "Coordenadores" }
    heading.parent.css("ul li span").map { |span| span.text.strip }
  end

  def revogar_on_coordinator_row(email)
    heading = page_doc(response.body).css("h3").find { |node| node.text.strip == "Coordenadores" }
    row = heading.parent.css("ul li").find { |li| li.at_css("span").text.strip == email }
    row.css("button").find { |button| button.text.strip == "Revogar" }
  end

  def revogar_on_submitter_row(email)
    heading = page_doc(response.body).css("h3").find { |node| node.text.strip == "Submitters" }
    row = heading.parent.css("ul li").find { |li| li.at_css("span").text.strip == email }
    row.css("button").find { |button| button.text.strip == "Revogar" }
  end
end
