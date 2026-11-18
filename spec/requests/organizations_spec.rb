require "rails_helper"

RSpec.describe "Organization home", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  it "home pending invites show kind in email order under Convites pendentes" do
    account, organization = plant_coordinator(email: "coord@example.com")
    Invite.create!(organization: organization, email: "zoe@exemplo.org", kind: :submitter)
    Invite.create!(organization: organization, email: "ana@exemplo.org", kind: :coordinator)
    sign_in_as(account, organization: organization)

    get "/"

    ana = pending_invite_item(response.body, "ana@exemplo.org")
    zoe = pending_invite_item(response.body, "zoe@exemplo.org")
    expect(ana).to be_present
    expect(zoe).to be_present
    expect(response.body.index("ana@exemplo.org")).to be < response.body.index("zoe@exemplo.org")
    expect(ana.text).to include("Coordenador")
    expect(ana.text).not_to include("Submitter")
    expect(zoe.text).to include("Submitter")
    expect(zoe.text).not_to include("Coordenador")

    doc = page_doc(response.body)
    invites_heading = doc.css("h2").find { |h2| h2.text.strip == "Convites pendentes" }
    invites_section = invites_heading.parent
    expect(invites_section.text).to include("E-mail")
    expect(invites_section.text).to include("Tipo")
    expect(invites_section.text).to include("Status")
    expect(invites_section.css("li").map(&:text).join).to include("ana@exemplo.org")
    expect(invites_section.css("li").map(&:text).join).to include("zoe@exemplo.org")
    pessoas = doc.at_css("details")
    expect(pessoas.at_css("summary").text.strip).to eq("Pessoas")
    expect(pessoas.css("h2").map { |h2| h2.text.strip }).to include("Convites pendentes")
    coordenadores = pessoas.css("h3").find { |node| node.text.strip == "Coordenadores" }.parent
    expect(coordenadores.css("li").map(&:text).join).not_to include("ana@exemplo.org")
    expect(coordenadores.css("li").map(&:text).join).not_to include("zoe@exemplo.org")
  end

  it "home pending invite shows exactly one last-delivery copy" do
    account, organization = plant_coordinator(email: "coord@example.com")
    Invite.create!(organization: organization, email: "ok@exemplo.org", kind: :coordinator, last_delivery: :sent)
    Invite.create!(organization: organization, email: "fail@exemplo.org", kind: :submitter, last_delivery: :failed)
    sign_in_as(account, organization: organization)

    get "/"

    sent_item = pending_invite_item(response.body, "ok@exemplo.org")
    failed_item = pending_invite_item(response.body, "fail@exemplo.org")
    expect(sent_item.text).to include("enviado")
    expect(sent_item.text).not_to include("falhou envio do e-mail")
    expect(failed_item.text).to include("falhou envio do e-mail")
    expect(failed_item.text).not_to include("enviado")
  end

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
    expect(doc.at_css('nav[aria-label="Organizações"]')).to be_nil
    expect(doc.css("h2").map { |h2| h2.text.strip }).to include("Meses")
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
    expect(doc.at_css('label[for="year_month"]').text.strip).to eq("Abrir mês")
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
    expect(link.text).to include("maio de 2026")
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
    expect(response.body).not_to include("Continuar")
    expect(response.body).not_to include("Contas bancárias")
    expect(response.body).not_to include("Fechar para envio")
    expect(response.body).not_to include("Configuração")
    expect(response.body).not_to include("Convidar coordenador")
  end

  it "home h1 is Inicio and an open month row says Aberto" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    Month.open(organization: organization, year_month: "2026-05")

    get "/"

    month_rows = rows(response.body, "month")
    expect(month_rows.size).to eq(1)
    expect(month_rows.first.at_css('a[href="/months/2026-05"]')).not_to be_nil
    expect(month_rows.first.text).to include("maio de 2026")
    expect(month_rows.first.text).to include("Aberto")
    expect(month_rows.first.text).not_to include("Fechado")
  end

  def month_delete_form(row, year_month)
    row.css("form").find do |form|
      form["action"] == "/months/#{year_month}" && form.at_css('input[name="_method"][value="delete"]')
    end
  end

  it "never-sent open month row includes Excluir with turbo confirm" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    Month.open(organization: organization, year_month: "2026-05")

    get "/"

    month_row = rows(response.body, "month").first
    expect(month_row.text).to include("Aberto")
    form = month_delete_form(month_row, "2026-05")
    expect(form).to be_present
    expect(form["data-turbo-confirm"]).to eq("Excluir este fechamento?")
    expect(form.at_css('button, input[type="submit"]').text).to include("Excluir")
    expect(month_row.text).to include("Aberto")
  end

  it "reopened month row omits Excluir" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month = Month.open(organization: organization, year_month: "2026-05")
    month.update!(closed: false, month_folder_id: "drive-folder")

    get "/"

    month_row = rows(response.body, "month").first
    expect(month_row.text).to include("Aberto")
    expect(month_delete_form(month_row, "2026-05")).to be_nil
    expect(month_row.text).not_to include("Excluir")
  end

  it "confirmed never-sent month row includes Excluir" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month = Month.open(organization: organization, year_month: "2026-05")
    month.update!(accounts_confirmed: true)

    get "/"

    month_row = rows(response.body, "month").first
    form = month_delete_form(month_row, "2026-05")
    expect(form).to be_present
    expect(form["data-turbo-confirm"]).to eq("Excluir este fechamento?")
    expect(form.at_css('button, input[type="submit"]').text).to include("Excluir")
  end

  it "submitter home omits Excluir" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    Month.open(organization: organization, year_month: "2026-05")
    sign_in_as(submitter, organization: organization)

    get "/"

    expect(response.body).not_to include("Excluir")
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
    expect(month_row.text).not_to include("Excluir")
    expect(month_delete_form(month_row, "2026-05")).to be_nil
  end

  it "submitter home says Inicio and points to Documentos" do
    account, organization = plant_submitter
    sign_in_as(account, organization: organization)

    get "/"

    doc = page_doc(response.body)
    expect(doc.at_css("h1").text.strip).to eq("Início")
    expect(doc.at_css('nav[aria-label="Organizações"]')).to be_nil
    expect(doc.at_css('[role="group"][aria-label="Organização"]')).to be_nil
    expect(response.body).to include("Inclua e acompanhe seus documentos de suporte em")
    expect(doc.at_css('main a[href="/supporting_documents"]')).not_to be_nil
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

  it "coordinator home main is a two-column grid with first column 26rem" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/"

    expect(page_doc(response.body).at_css("main")["class"]).to include("md:grid-cols-[26rem_1fr]")
  end

  it "one-organization home omits Organizacoes nav and names the org in the header" do
    account, organization = plant_coordinator(organization_name: "ONG Norte")
    sign_in_as(account, organization: organization)

    get "/"

    doc = page_doc(response.body)
    expect(response).to have_http_status(:ok)
    expect(doc.at_css('nav[aria-label="Organizações"]')).to be_nil
    expect(doc.at_css('[role="group"][aria-label="Organização"]')).to be_nil
    expect(doc.css("h1, h2, h3, p, legend, summary").map { |node| node.text.strip }).not_to include("Organizações")
    expect(doc.at_css("header").text).to include("ONG Norte")
  end

  it "Abrir mes is label select and submit on one row above Meses posting to /months" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/"

    doc = page_doc(response.body)
    index = doc.at_css('[data-desk="index"]')
    label = index.at_css('label[for="year_month"]')
    expect(label.text.strip).to eq("Abrir mês")
    open_form = index.css("form").find { |form| form.at_css('input[type="submit"][value="Abrir mês"]') }
    expect(open_form["action"]).to eq("/months")
    row = open_form.at_css("div")
    expect(row.at_css("select#year_month")).to be_present
    expect(row.at_css('input[type="submit"][value="Abrir mês"]')).to be_present
    expect(row["class"]).to include("flex-nowrap")
    meses = index.css("h2").find { |h2| h2.text.strip == "Meses" }
    expect(index.inner_html.index(open_form.to_html)).to be < index.inner_html.index(meses.to_html)
  end

  it "empty home lists Nenhum mes aberto and omits Continuar" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/"

    index = page_doc(response.body).at_css('[data-desk="index"]')
    expect(index.text).to include("Nenhum mês aberto")
    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.css("a").map { |link| link.text.strip }).not_to include("Continuar")
  end

  it "open month row says em trabalho and Aberto, closed row stamps Fechado, year_month desc" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    closed = Month.open(organization: organization, year_month: "2026-09")
    closed.update!(closed: true)
    Month.open(organization: organization, year_month: "2026-08")
    Month.open(organization: organization, year_month: "2026-10")

    get "/"

    month_rows = rows(response.body, "month")
    expect(month_rows.map { |row| row.at_css("a")["href"] }).to eq(
      [ "/months/2026-10", "/months/2026-09", "/months/2026-08" ]
    )
    open_row = month_rows[0]
    expect(open_row.at_css("a").text).to include("outubro de 2026")
    expect(open_row.text).to include("em trabalho")
    expect(open_row.text).to include("Aberto")
    closed_row = month_rows[1]
    expect(closed_row.at_css("a").text).to include("setembro de 2026")
    expect(closed_row.at_css(".stamp-closed-row").text.strip).to eq("Fechado")
    expect(closed_row.text).not_to include("em trabalho")
    older_open = month_rows[2]
    expect(older_open.at_css("a").text).to include("agosto de 2026")
    expect(older_open.text).to include("Aberto")
    expect(older_open.text).not_to include("em trabalho")
  end

  it "in-work month 2026-10 right h1 is outubro de 2026 with Continuar to /months/2026-10" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization, year_month: "2026-10")

    get "/"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.at_css("h1").text.strip).to eq("outubro de 2026")
    expect(in_work.text).to include("2026-10")
    continuar = in_work.css("a").find { |link| link.text.strip == "Continuar" }
    expect(continuar["href"]).to eq("/months/2026-10")
  end

  it "in-work summary says 3 pagamentos com documento faltante in margem without Falta o extrato" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "104")
    _month, statement = plant_month(organization, year_month: "2026-10")
    3.times { |i| plant_payment(statement, 1000 + i) }
    plant_payment(statement, 1550, history: "Tarifa").mark_document_exception("bank_fee")

    get "/"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    sentences = in_work.css('[data-desk="missing"]')
    expect(sentences.size).to eq(1)
    expect(sentences.first.text.strip).to eq("3 pagamentos com documento faltante.")
    expect(sentences.first["class"]).to include("text-margem")
    expect(sentences.first.text).not_to include("Falta o extrato")
    expect(in_work.text).not_to include("Falta o extrato")
  end

  it "in-work summary says 1 pagamento com documento faltante" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization, year_month: "2026-10")
    plant_payment(statement, 22000)

    get "/"

    sentence = page_doc(response.body).at_css('[data-desk="missing"]')
    expect(sentence.text.strip).to eq("1 pagamento com documento faltante.")
  end

  it "in-work summary says Nenhum documento faltante without margem" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization, year_month: "2026-10")

    get "/"

    sentence = page_doc(response.body).at_css('[data-desk="missing"]')
    expect(sentence.text.strip).to eq("Nenhum documento faltante.")
    expect(sentence["class"].to_s).not_to include("margem")
  end

  it "unconfirmed in-work month omits documento faltante" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization, year_month: "2026-10", accounts_confirmed: false)
    plant_payment(statement, 22000)

    get "/"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.text).not_to include("documento faltante")
  end

  it "in-work Contas bancarias Extrato is Presente and Falta in margem" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "104")
    plant_month(organization, year_month: "2026-10")

    get "/"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    head = in_work.at_css(".ledger-head")
    expect(head.element_children.map { |node| node.text.strip }).to eq([ "Banco", "Nome", "Extrato" ])
    sheet_rows = rows(response.body, "bank-account")
    presente = sheet_rows.find { |row| row.text.include?("Presente") }
    falta = sheet_rows.find { |row| row.text.include?("Falta") }
    expect(presente.text).to include("Conta Principal")
    expect(falta.text).to include("Conta Alfa")
    expect(falta.at_css(".text-margem").text.strip).to eq("Falta")
    expect(presente.text).not_to include("Falta")
  end

  it "all-closed home omits Continuar and Contas bancarias" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month = Month.open(organization: organization, year_month: "2026-10")
    month.update!(closed: true)

    get "/"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.css("a").map { |link| link.text.strip }).not_to include("Continuar")
    expect(in_work.text).not_to include("Contas bancárias")
  end

  it "in-work skips a newer closed month" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization, year_month: "2026-09")
    closed = Month.open(organization: organization, year_month: "2026-10")
    closed.update!(closed: true)

    get "/"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.at_css("h1").text.strip).to eq("setembro de 2026")
    continuar = in_work.css("a").find { |link| link.text.strip == "Continuar" }
    expect(continuar["href"]).to eq("/months/2026-09")
  end

  it "in-work is the newest of two open months" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization, year_month: "2026-08")
    plant_month(organization, year_month: "2026-10")

    get "/"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.at_css("h1").text.strip).to eq("outubro de 2026")
  end

  it "Pessoas is a closed details below the desk" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/"

    doc = page_doc(response.body)
    pessoas = doc.at_css("details")
    expect(pessoas.at_css("summary").text.strip).to eq("Pessoas")
    expect(pessoas.has_attribute?("open")).to eq(false)
    expect(pessoas.css("h2").map { |h2| h2.text.strip }).to include("Convites pendentes")
    expect(pessoas.css("h3").map { |h3| h3.text.strip }).to include("Coordenadores")
    main_html = doc.at_css("main").inner_html
    expect(main_html.index('data-desk="index"')).to be < main_html.index("<details")
    expect(main_html.index('data-desk="in-work"')).to be < main_html.index("<details")
  end

  it "submitter two-organization home shows Organizacao chips" do
    account, first = plant_submitter(email: "sub@example.com", organization_name: "ONG Norte")
    second = create_organization!(name: "ONG Sul")
    Access.create!(account: account, organization: second, kind: :submitter)
    sign_in_as(account, organization: first)

    get "/"

    group = page_doc(response.body).at_css('[role="group"][aria-label="Organização"]')
    expect(group.css("button").map { |button| button.text.strip }).to contain_exactly("ONG Norte", "ONG Sul")
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("Início")
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
    heading.parent.css('ul li [data-cell="email"]').map { |span| span.text.strip }
  end

  def revogar_on_coordinator_row(email)
    heading = page_doc(response.body).css("h3").find { |node| node.text.strip == "Coordenadores" }
    row = heading.parent.css("ul li").find { |li| li.at_css('[data-cell="email"]').text.strip == email }
    row.css("button").find { |button| button.text.strip == "Revogar" }
  end

  def revogar_on_submitter_row(email)
    heading = page_doc(response.body).css("h3").find { |node| node.text.strip == "Submitters" }
    row = heading.parent.css("ul li").find { |li| li.at_css('[data-cell="email"]').text.strip == email }
    row.css("button").find { |button| button.text.strip == "Revogar" }
  end
end
