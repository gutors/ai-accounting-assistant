require "rails_helper"

RSpec.describe "Administration", type: :request do
  include AdministrationHelpers

  it "signed-out administration routes redirect to /login" do
    expect {
      administration_routes.each do |verb, path|
        public_send(verb, path, params: { name: "ONG Norte", email: "coordenador@exemplo.org", organization_id: "1" })
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to("/login")
      end
    }.not_to change { [ Organization.count, Account.count, Access.count, Invite.count, ActionMailer::Base.deliveries.size ] }
  end

  it "non-administrator and blank allowlist administration routes respond 404" do
    account, organization = plant_coordinator(email: "other@example.com", organization_name: "ONG Sul")
    sign_in_as(account, organization: organization)

    [ "seller@example.com", nil, "" ].each do |allow|
      with_env("ADMINISTRATOR_EMAIL" => allow) do
        administration_routes.each do |verb, path|
          expect {
            public_send(verb, path, params: { name: "ONG Norte", email: "coordenador@exemplo.org", organization_id: "1" })
          }.not_to change { [ Organization.count, Account.count, Access.count, Invite.count, ActionMailer::Base.deliveries.size ] }
          expect(response).to have_http_status(:not_found)
          expect(response.body).to eq("")
        end
      end
    end
  end

  it "GET /administration renders the empty registration form" do
    as_seller { get "/administration" }

    expect_empty_form
  end

  it "header without a focused organization shows the product name and Sair" do
    as_seller { get "/administration" }

    header = page.at_css("header")
    expect(header.text).to include("Fechamento mensal")
    sair = header.css("button").select { |button| button.text.strip == "Sair" }
    expect(sair.size).to eq(1)
    expect(sair.first["class"]).to include("text-caixa")
    form = sair.first.ancestors("form").first
    expect(form["action"]).to eq("/session")
    expect(form.at_css('input[name="_method"]')["value"]).to eq("delete")
    %w[Início Documentos Configuração Administração].each do |label|
      expect(header.text).not_to include(label)
    end
  end

  it "blank organization name re-renders 422 and writes nothing" do
    listed = Organization.create!(name: "ONG Norte")
    as_seller do
      expect {
        post "/administration", params: { name: "   ", email: "coordenador@exemplo.org" }
      }.not_to change { [ Organization.count, Account.count, Access.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      notices = page.css("[data-notice='error']").map { |notice| notice.text.strip }
      expect(notices).to eq([ "Informe o nome da organização." ])
      expect(response.body.index("Administração")).to be < response.body.index("Informe o nome da organização.")
      expect(page.at_css('input[name="name"]')["value"]).to eq("   ")
      expect(page.at_css('input[name="email"]')["value"]).to eq("coordenador@exemplo.org")
      expect(organization_row(listed).text).to include("ONG Norte")
      expect(session[:administration_pending]).to be_nil
    end
  end

  it "invalid coordinator email re-renders 422 and writes nothing" do
    listed = Organization.create!(name: "ONG Norte")
    as_seller do
      expect {
        post "/administration", params: { name: "ONG Sul", email: "nao-e-email" }
      }.not_to change { [ Organization.count, Account.count, Access.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      notices = page.css("[data-notice='error']").map { |notice| notice.text.strip }
      expect(notices).to eq([ "Informe um e-mail válido." ])
      expect(page.at_css('input[name="name"]')["value"]).to eq("ONG Sul")
      expect(page.at_css('input[name="email"]')["value"]).to eq("nao-e-email")
      expect(organization_row(listed).text).to include("ONG Norte")
      expect(session[:administration_pending]).to be_nil
    end
  end

  it "blank name and invalid email re-render both notices" do
    listed = Organization.create!(name: "ONG Norte")
    as_seller do
      expect {
        post "/administration", params: { name: "   ", email: "nao-e-email" }
      }.not_to change { [ Organization.count, Account.count, Access.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      body = response.body
      name_at = body.index("Informe o nome da organização.")
      email_at = body.index("Informe um e-mail válido.")
      expect(name_at).to be < email_at
      expect(body.index("Administração")).to be < name_at
      expect(email_at).to be < body.index("Cadastre a organização e o coordenador que vai fechá-la.")
      expect(page.css("[data-notice='error']").map { |notice| notice.text.strip }).to eq([
        "Informe o nome da organização.",
        "Informe um e-mail válido."
      ])
      expect(organization_row(listed).text).to include("ONG Norte")
      expect(session[:administration_pending]).to be_nil
    end
  end

  it "valid POST stores pending and renders confirmation" do
    sul = Organization.create!(name: "ONG Sul")
    as_seller do
      expect {
        post "/administration", params: { name: "  ONG Norte  ", email: " Coordenador@Exemplo.ORG " }
      }.not_to change { [ Organization.count, Account.count, Access.count, ActionMailer::Base.deliveries.size ] }

      expect(session[:administration_pending]).to eq(
        "name" => "ONG Norte",
        "email" => "coordenador@exemplo.org",
        "confirming" => true
      )
      follow_administration
      expect(response).to have_http_status(:ok)
      expect(page.at_css("h1").text.strip).to eq("Administração")
      expect(response.body).to include("ONG Norte")
      expect(response.body).to include("coordenador@exemplo.org")
      expect(response.body).not_to include("Confirmar cadastro")
      expect(response.body).not_to include("Cadastre a organização e o coordenador que vai fechá-la.")
      expect(organization_row(sul).text).to include("Corrigir nome")
      ruled = page.at_css("main .border-b.border-rule")
      expect(ruled.text).to include("ONG Norte")
      expect(ruled.next_element.text).to include("coordenador@exemplo.org")
      group = page.at_css("main .flex-wrap")
      expect(group["class"]).to include("flex-wrap")
      expect(group.css("button").map { |node| node.text.strip }).to eq([ "Confirmar", "Corrigir" ])
      confirm = group.css("button").find { |button| button.text.strip == "Confirmar" }
      expect(confirm["class"]).to include("bg-caixa")
      expect(confirm.ancestors("form").first["action"]).to eq("/administration/confirm")
      correct = group.css("button").find { |button| button.text.strip == "Corrigir" }
      expect(correct.ancestors("form").first["action"]).to eq("/administration/correct")
      expect(correct["class"]).to include("border")
      expect(correct["class"]).to include("border-ink")
    end
  end

  it "confirmation column is 28rem and shows the record labels" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      follow_administration

      column = page.at_css("main div")
      expect(column["class"]).to include("max-w-[28rem]")
      expect(column["class"]).not_to include("mx-auto")
      ruled = page.at_css("main .border-b.border-rule")
      expect(ruled.text).to include("Nome da organização")
      expect(ruled.text).to include("ONG Norte")
      email_row = ruled.next_element
      expect(email_row.text).to include("E-mail do coordenador")
      expect(email_row.text).to include("coordenador@exemplo.org")
    end
  end

  it "GET /administration with pending keeps the confirmation" do
    sul = Organization.create!(name: "ONG Sul")
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      follow_administration
      get "/administration"

      expect(response).to have_http_status(:ok)
      expect(page.at_css("h1").text.strip).to eq("Administração")
      expect(response.body).not_to include("Cadastre a organização e o coordenador que vai fechá-la.")
      expect(page.at_css('form[action="/administration/confirm"]')).not_to be_nil
      expect(page.at_css('form[action="/administration"] input[name="name"]')).to be_nil
      expect(organization_row(sul).text).to include("Corrigir nome")
      expect(organization_row(sul).at_css('input[name="name"]')).to be_nil
    end
  end

  it "Corrigir on the registration confirmation returns the filled form" do
    sul = Organization.create!(name: "ONG Sul")
    as_seller do
      post "/administration", params: { name: "  ONG Norte  ", email: " Coordenador@Exemplo.ORG " }
      follow_administration
      expect {
        post "/administration/correct"
      }.not_to change { [ Organization.count, Account.count, Access.count ] }

      follow_administration
      expect(page.at_css('input[name="name"]')["value"]).to eq("ONG Norte")
      expect(page.at_css('input[name="email"]')["value"]).to eq("coordenador@exemplo.org")
      expect(response.body).to include("Cadastre a organização e o coordenador que vai fechá-la.")
      expect(organization_row(sul).text).to include("Corrigir nome")
    end
  end

  it "confirm creates the organization and shows the sent mail" do
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      post "/administration/confirm"

      organization = Organization.find_by!(name: "ONG Norte")
      account = Account.find_by!(email: "coordenador@exemplo.org")
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to("/administration")
      expect(organization.accesses.find_by!(account: account).kind).to eq("coordinator")
      expect(Invite.count).to eq(0)
      expect(session[:administration_pending]).to be_nil
      expect(session[:administration_result]).to eq(
        "organization_id" => organization.id,
        "mail_sent" => true,
        "email" => "coordenador@exemplo.org",
        "kind" => "registration"
      )
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      message = ActionMailer::Base.deliveries.last
      expect(message.to).to eq([ "coordenador@exemplo.org" ])
      expect(message.subject).to eq("Fechamento Mensal - Cadastro da Organização ONG Norte")
      expect(message.body.decoded).to eq(
        "A organização ONG Norte está pronta. Entre com o Google usando coordenador@exemplo.org, pelo botão Entrar com Google."
      )

      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(page.at_css("h1").text.strip).to eq("Administração")
      expect(response.body).to include("Cadastre a organização e o coordenador que vai fechá-la.")
      expect(page.at_css('input[name="name"]')["value"].to_s).to eq("")
      expect(page.at_css('input[name="email"]')["value"].to_s).to eq("")
      row = organization_row(organization)
      sentence = row.css("p").find { |node| node.text.include?("E-mail enviado para coordenador@exemplo.org.") }
      expect(sentence).not_to be_nil
      expect(sentence["data-notice"]).to be_nil
      expect(row.text).not_to include("Reenviar e-mail")
      expect(response.body).not_to include("Cadastrar outra organização")
      expect(page.css("[data-notice='error']")).to be_empty
    end
  end

  it "confirm reuses an existing Account" do
    Account.create!(email: "coordenador@exemplo.org")
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      expect {
        post "/administration/confirm"
      }.not_to change(Account, :count)

      organization = Organization.find_by!(name: "ONG Norte")
      account = Account.find_by!(email: "coordenador@exemplo.org")
      expect(organization.accesses.where(account: account, kind: "coordinator").count).to eq(1)
      expect(Invite.count).to eq(0)
      follow_redirect!
      expect(organization_row(organization).text).to include("E-mail enviado para coordenador@exemplo.org.")
    end
  end

  it "confirm of the signed-in email focuses the new organization" do
    _account, previous = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Sul",
      google_uid: "uid-seller"
    )
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "seller@example.com" }
      post "/administration/confirm"

      created = Organization.find_by!(name: "ONG Norte")
      expect(session[:organization_id]).to eq(created.id)
      expect(session[:organization_id]).not_to eq(previous.id)
      follow_redirect!
      expect(page.at_css("header").text).to include("ONG Norte")
    end
  end

  it "confirm of another email leaves the focused organization" do
    _account, previous = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Sul",
      google_uid: "uid-seller"
    )
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      post "/administration/confirm"

      expect(session[:organization_id]).to eq(previous.id)
    end
  end

  it "confirm without pending writes nothing and keeps the result" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      post "/administration/confirm"
      result = session[:administration_result]
      expect(session[:administration_pending]).to be_nil

      expect {
        post "/administration/confirm"
      }.not_to change { [ Organization.count, Account.count, Access.count, ActionMailer::Base.deliveries.size ] }

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to("/administration")
      expect(session[:administration_result]).to eq(result)
    end
  end

  it "confirm keeps the rows when deliver_now raises" do
    sul = Organization.create!(name: "ONG Sul")
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      raise_delivery
      post "/administration/confirm"

      organization = Organization.find_by!(name: "ONG Norte")
      account = Account.find_by!(email: "coordenador@exemplo.org")
      expect(organization.accesses.find_by!(account: account).kind).to eq("coordinator")
      expect(Invite.count).to eq(0)
      expect(session[:administration_pending]).to be_nil
      expect(session[:administration_result]).to eq(
        "organization_id" => organization.id,
        "mail_sent" => false,
        "email" => "coordenador@exemplo.org",
        "kind" => "registration"
      )
      expect(response).to redirect_to("/administration")

      follow_redirect!
      norte_row = organization_row(organization)
      sul_row = organization_row(sul)
      notice = norte_row.at_css("[data-notice='error']")
      expect(notice.text.strip).to eq("O cadastro foi gravado, mas o e-mail não saiu.")
      expect(sul_row.at_css("[data-notice='error']")).to be_nil
      resend = norte_row.css("button").find { |button| button.text.strip == "Reenviar e-mail" }
      expect(resend["class"]).to include("bg-caixa")
      expect(resend["class"]).to include("font-semibold")
      expect(resend["class"]).to include("text-white")
      expect(resend.ancestors("form").first["action"]).to eq("/administration/mail")
      expect(sul_row.text).not_to include("Reenviar e-mail")
      expect(response.body).not_to include("E-mail enviado para")
      expect(response.body).not_to include("Cadastrar outra organização")
    end
  end

  it "mail failure shows the saved record" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      raise_delivery
      post "/administration/confirm"
      follow_redirect!

      organization = Organization.find_by!(name: "ONG Norte")
      row = organization_row(organization)
      expect(row.at_css("[data-notice='error']").text).to include("O cadastro foi gravado, mas o e-mail não saiu.")
      expect(row.text).to include("ONG Norte")
      expect(row.text).to include("coordenador@exemplo.org")
    end
  end

  it "resend delivers another welcome message" do
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      raise_delivery
      post "/administration/confirm"
      allow(CoordinatorWelcomeMailer).to receive(:welcome).and_call_original

      expect {
        post "/administration/mail"
      }.not_to change(Organization, :count)

      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(session[:administration_result]["mail_sent"]).to be(true)
      follow_redirect!
      organization = Organization.find_by!(name: "ONG Norte")
      row = organization_row(organization)
      expect(row.text).to include("E-mail enviado para coordenador@exemplo.org.")
      expect(row.text).not_to include("Reenviar e-mail")
      expect(row.text).not_to include("A correção foi gravada, mas o e-mail não saiu.")
    end
  end

  it "resend keeps mail_sent false when deliver_now raises" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      post "/administration/confirm"
      raise_delivery

      expect {
        post "/administration/mail"
      }.not_to change(Organization, :count)

      expect(session[:administration_result]["mail_sent"]).to be(false)
      follow_redirect!
      organization = Organization.find_by!(name: "ONG Norte")
      expect(organization_row(organization).text).to include("O cadastro foi gravado, mas o e-mail não saiu.")
      expect(organization_row(organization).text).not_to include("A correção foi gravada, mas o e-mail não saiu.")
    end
  end

  it "resend without a result redirects and delivers nothing" do
    as_seller do
      ActionMailer::Base.deliveries.clear
      expect {
        post "/administration/mail"
      }.not_to change { [ Organization.count, Account.count, Access.count, ActionMailer::Base.deliveries.size ] }

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to("/administration")
    end
  end

  it "another registration clears the result and keeps the organization" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      post "/administration/confirm"
      organization = Organization.find_by!(name: "ONG Norte")

      post "/administration/another"
      expect(session[:administration_result]).to be_nil
      expect(Organization.find_by(id: organization.id)).to eq(organization)

      follow_redirect!
      expect(page.at_css('input[name="name"]')["value"].to_s).to eq("")
      expect(page.at_css('input[name="email"]')["value"].to_s).to eq("")
      expect(organization_row(organization).text).to include("ONG Norte")
      expect(response.body).not_to include("E-mail enviado para")
    end
  end

  it "sign out drops a pending registration and writes no organization" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      expect(session[:administration_pending]).to be_present

      expect {
        delete "/session"
      }.not_to change(Organization, :count)

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to("/login")
      expect(session[:administration_pending]).to be_nil
      expect(session[:administration_result]).to be_nil
      follow_redirect!
      get "/administration"
      expect(session[:administration_pending]).to be_nil
      expect(session[:administration_result]).to be_nil
    end
  end

  it "sign out drops a confirmed result and keeps the organization" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      post "/administration/confirm"
      organization = Organization.find_by!(name: "ONG Norte")

      delete "/session"

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to("/login")
      expect(session[:administration_result]).to be_nil
      expect(session[:administration_pending]).to be_nil
      expect(Organization.find_by(id: organization.id)).to eq(organization)
      get "/login"
      expect(session[:administration_pending]).to be_nil
      expect(session[:administration_result]).to be_nil
    end
  end

  it "saved registration returns an empty form and keeps the stored record" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      raise_delivery
      post "/administration/confirm"
      follow_redirect!

      expect(page.at_css('input[name="name"]')["value"].to_s).to eq("")
      expect(page.at_css('input[name="email"]')["value"].to_s).to eq("")
      expect(Organization.find_by!(name: "ONG Norte").name).to eq("ONG Norte")
      expect(Account.find_by!(email: "coordenador@exemplo.org").email).to eq("coordenador@exemplo.org")

      allow(CoordinatorWelcomeMailer).to receive(:welcome).and_call_original
      post "/administration/mail"
      follow_redirect!

      expect(page.at_css('input[name="name"]')["value"].to_s).to eq("")
      expect(page.at_css('input[name="email"]')["value"].to_s).to eq("")
      expect(Organization.find_by!(name: "ONG Norte").name).to eq("ONG Norte")
      expect(Account.find_by!(email: "coordenador@exemplo.org").email).to eq("coordenador@exemplo.org")
    end
  end

  it "taken organization name re-renders 422 and stores no pending" do
    Organization.create!(name: "ONG Norte")
    as_seller do
      expect {
        post "/administration", params: { name: "  ong norte  ", email: "coordenador@exemplo.org" }
      }.not_to change { [ Organization.count, Account.count, Access.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(page.css("[data-notice='error']").map { |notice| notice.text.strip }).to eq([
        "Já existe uma organização com esse nome."
      ])
      expect(page.at_css('input[name="name"]')["value"]).to eq("  ong norte  ")
      expect(page.at_css('input[name="email"]')["value"]).to eq("coordenador@exemplo.org")
      expect(page.at_css("h2").text.strip).to eq("Organizações")
      expect(session[:administration_pending]).to be_nil
    end
  end

  it "taken name ONG NORTE with surrounding spaces re-renders 422" do
    Organization.create!(name: "ONG Norte")
    as_seller do
      expect {
        post "/administration", params: { name: "  ONG NORTE  ", email: "outro@exemplo.org" }
      }.not_to change { [ Organization.count, Account.count, Access.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(page.css("[data-notice='error']").map { |notice| notice.text.strip }).to eq([
        "Já existe uma organização com esse nome."
      ])
      expect(page.at_css('input[name="name"]')["value"]).to eq("  ONG NORTE  ")
      expect(page.at_css('input[name="email"]')["value"]).to eq("outro@exemplo.org")
      expect(session[:administration_pending]).to be_nil
    end
  end

  it "taken name and invalid email re-render both notices" do
    listed = Organization.create!(name: "ONG Norte")
    as_seller do
      expect {
        post "/administration", params: { name: "  ong norte  ", email: "nao-e-email" }
      }.not_to change { [ Organization.count, Account.count, Access.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(page.css("[data-notice='error']").map { |notice| notice.text.strip }).to eq([
        "Informe um e-mail válido.",
        "Já existe uma organização com esse nome."
      ])
      expect(page.at_css('input[name="name"]')["value"]).to eq("  ong norte  ")
      expect(page.at_css('input[name="email"]')["value"]).to eq("nao-e-email")
      expect(organization_row(listed).text).to include("ONG Norte")
      expect(session[:administration_pending]).to be_nil
    end
  end

  it "GET /administration lists organizations in stored-name order" do
    _account, sul = plant_coordinator(email: "sul@exemplo.org", organization_name: "ONG Sul", google_uid: "uid-sul")
    norte = Organization.create!(name: "ONG Norte")
    zoe = Account.create!(email: "zoe@exemplo.org")
    ana = Account.create!(email: "ana@exemplo.org")
    submitter = Account.create!(email: "submitter@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    Access.create!(account: ana, organization: norte, kind: :coordinator)
    Access.create!(account: submitter, organization: norte, kind: :submitter)
    ama = Organization.create!(name: "AMA")
    Access.create!(account: ana, organization: ama, kind: :coordinator)

    as_seller do
      get "/administration"

      expect(response).to have_http_status(:ok)
      expect(page.at_css("h1").text.strip).to eq("Administração")
      expect(response.body).to include("Cadastre a organização e o coordenador que vai fechá-la.")
      expect(page.at_css('input[name="name"]')["value"].to_s).to eq("")
      expect(page.at_css('input[type="submit"]')["value"]).to eq("Continuar")
      column = administration_column
      children = column.element_children
      form_index = children.index { |node| node.name == "form" }
      heading_index = children.index { |node| node.name == "h2" }
      expect(form_index).to be < heading_index
      heading = children[heading_index]
      expect(heading.text.strip).to eq("Organizações")
      expect(heading["class"]).to include("border-b")
      expect(heading["class"]).to include("border-rule")
      expect(page.css("[data-organization-id]").map { |node| node["data-organization-id"].to_i }).to eq([
        ama.id, norte.id, sul.id
      ])
      row = organization_row(norte)
      expect(row["class"]).to include("flex-wrap")
      expect(row["class"]).to include("border-b")
      expect(row["class"]).to include("border-rule")
      expect(column.css("[data-organization-id='#{norte.id}']").size).to eq(1)
      html = row.inner_html
      expect(html.index("ONG Norte")).to be < html.index("Corrigir nome")
      expect(html.index("Corrigir nome")).to be < html.index("ana@exemplo.org")
      expect(html.index("ana@exemplo.org")).to be < html.index("zoe@exemplo.org")
      correct = row.css("button").find { |button| button.text.strip == "Corrigir nome" }
      expect(correct["class"]).to include("text-caixa")
      expect(correct["class"]).to include("underline")
      expect(correct["class"]).to include("underline-offset-2")
      expect(response.body).not_to include("submitter@exemplo.org")
    end
  end

  it "a later registration replaces the failure notice" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      raise_delivery
      post "/administration/confirm"
      allow(CoordinatorWelcomeMailer).to receive(:welcome).and_call_original
      post "/administration", params: { name: "ONG Sul", email: "sul@exemplo.org" }
      post "/administration/confirm"
      follow_redirect!

      norte = Organization.find_by!(name: "ONG Norte")
      sul = Organization.find_by!(name: "ONG Sul")
      expect(organization_row(norte).at_css("[data-notice='error']")).to be_nil
      expect(organization_row(norte).text).not_to include("Reenviar e-mail")
      expect(organization_row(sul).text).to include("E-mail enviado para sul@exemplo.org.")
    end
  end

  it "the sent sentence stays on the row after refresh" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      post "/administration/confirm"
      follow_redirect!
      organization = Organization.find_by!(name: "ONG Norte")

      get "/administration"

      expect(organization_row(organization).text).to include("E-mail enviado para coordenador@exemplo.org.")
    end
  end

  it "Corrigir nome opens the stored name" do
    _account, organization = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      ActionMailer::Base.deliveries.clear
      expect {
        post "/administration/name", params: { organization_id: organization.id }
      }.not_to change { organization.reload.name }

      follow_administration
      expect(ActionMailer::Base.deliveries).to be_empty
      row = organization_row(organization)
      field = row.at_css('input[name="name"]')
      expect(field["value"]).to eq("ONG Norte")
      label = row.at_css("label")
      expect(label.text.strip).to eq("Nome da organização")
      expect(label["for"]).to eq(field["id"])
      form = row.at_css("form#name_correction_form")
      expect(form.at_css('input[name="name"]')).to eq(field)
      submit = row.at_css('input[type="submit"]')
      expect(submit["value"]).to eq("Continuar")
      expect(submit["class"]).to include("bg-caixa")
      expect(submit["form"]).to eq("name_correction_form")
      group = submit.parent
      expect(group["class"]).to include("flex-wrap")
      expect(group.css("input[type='submit'], button").map { |node| node["value"] || node.text.strip }).to eq([
        "Continuar", "Cancelar"
      ])
      cancel = row.css("button").find { |button| button.text.strip == "Cancelar" }
      expect(cancel["class"]).to include("text-caixa")
      expect(cancel["class"]).to include("underline")
      expect(cancel["class"]).to include("underline-offset-2")
      expect(row.inner_html.index("Cancelar")).to be < row.inner_html.index("coordenador@exemplo.org")
      expect(row.text).to include("coordenador@exemplo.org")
      expect(row.at_css('input[type="email"]')).to be_nil
    end
  end

  it "Cancelar on the name field restores the row" do
    _account, organization = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration/name", params: { organization_id: organization.id }
      session[:administration_name] = {
        "organization_id" => organization.id,
        "name" => "ONG Norte Nova",
        "confirming" => false
      }

      expect {
        post "/administration/name/cancel"
      }.not_to change { organization.reload.name }
      expect(ActionMailer::Base.deliveries).to be_empty

      follow_redirect!
      row = organization_row(organization)
      expect(row.text).to include("ONG Norte")
      expect(row.text).to include("Corrigir nome")
      expect(row.at_css('input[name="name"]')).to be_nil
      expect(organization.name).to eq("ONG Norte")
    end
  end

  it "blank name correction re-renders 422" do
    _account, organization = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      post "/administration/name", params: { organization_id: organization.id }
      post "/administration/name/continue", params: { name: "   " }

      expect(response).to have_http_status(:unprocessable_content)
      expect(page.css("[data-notice='error']").map { |notice| notice.text.strip }).to eq([
        "Informe o nome da organização."
      ])
      expect(response.body.index("Administração")).to be < response.body.index("Informe o nome da organização.")
      row = organization_row(organization)
      expect(row.at_css('input[name="name"]')["value"]).to eq("   ")
      expect(row.text).not_to include("Nenhum e-mail será enviado.")
      expect(organization.reload.name).to eq("ONG Norte")
    end
  end

  it "taken name correction re-renders 422" do
    _account, organization = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    Organization.create!(name: "ONG Sul")
    as_seller do
      post "/administration/name", params: { organization_id: organization.id }
      post "/administration/name/continue", params: { name: "ong sul" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(page.css("[data-notice='error']").map { |notice| notice.text.strip }).to eq([
        "Já existe uma organização com esse nome."
      ])
      row = organization_row(organization)
      expect(row.at_css('input[name="name"]')["value"]).to eq("ong sul")
      expect(row.text).not_to include("Nenhum e-mail será enviado.")
      expect(organization.reload.name).to eq("ONG Norte")
    end
  end

  it "a lower-case spelling of the same name asks for confirmation" do
    _account, organization = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    sul = Organization.create!(name: "ONG Sul")
    as_seller do
      post "/administration/name", params: { organization_id: organization.id }
      expect {
        post "/administration/name/continue", params: { name: "ong norte" }
      }.not_to change { organization.reload.name }

      follow_administration
      expect(response).to have_http_status(:ok)
      expect(page.css("[data-notice='error']")).to be_empty
      row = organization_row(organization)
      html = row.inner_html
      expect(html.index("Nome da organização")).to be < html.index("ong norte")
      expect(html.index("ong norte")).to be < html.index("Nenhum e-mail será enviado.")
      expect(row.text).not_to include("coordenador@exemplo.org")
      sentence = row.css("p").find { |node| node.text.include?("Nenhum e-mail será enviado.") }
      expect(sentence["data-notice"]).to be_nil
      group = row.at_css(".flex-wrap")
      expect(group.css("button").map { |node| node.text.strip }).to eq([ "Confirmar", "Corrigir" ])
      confirm = group.css("button").find { |button| button.text.strip == "Confirmar" }
      expect(confirm["class"]).to include("bg-caixa")
      expect(confirm.ancestors("form").first["action"]).to eq("/administration/name/confirm")
      correct = group.css("button").find { |button| button.text.strip == "Corrigir" }
      expect(correct.ancestors("form").first["action"]).to eq("/administration/correct")
      expect(correct["class"]).to include("border-ink")
      expect(organization_row(sul).text).to include("Corrigir nome")
    end
  end

  it "confirming a name correction stores the stripped name and does not call the writer" do
    _account, organization = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    month, _statement = plant_month(organization)
    month.update!(closed: true, month_folder_id: "folder-norte")
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration/name", params: { organization_id: organization.id }
      post "/administration/name/continue", params: { name: "  ong norte  " }
      follow_administration
      expect(organization_row(organization).text).to include("ong norte")
      expect(PackageArchiveWriter).not_to receive(:current)

      expect {
        post "/administration/name/confirm", params: { organization_id: organization.id }
      }.not_to change { ActionMailer::Base.deliveries.size }

      follow_redirect!
      expect(organization.reload.name).to eq("ong norte")
      expect(month.reload.month_folder_id).to eq("folder-norte")
      expect(response.body).not_to include("Nenhum e-mail será enviado.")
      expect(organization_row(organization).text).to include("ong norte")
    end
  end

  it "renaming keeps the mail failure on that row" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      raise_delivery
      post "/administration/confirm"
      follow_redirect!
      organization = Organization.find_by!(name: "ONG Norte")
      ActionMailer::Base.deliveries.clear
      post "/administration/name", params: { organization_id: organization.id }
      post "/administration/name/continue", params: { name: "ONG Norte Nova" }

      expect {
        post "/administration/name/confirm", params: { organization_id: organization.id }
      }.not_to change { ActionMailer::Base.deliveries.size }

      follow_redirect!
      expect(organization.reload.name).to eq("ONG Norte Nova")
      row = organization_row(organization)
      expect(row.text).to include("ONG Norte Nova")
      expect(row.at_css("[data-notice='error']").text).to include("O cadastro foi gravado, mas o e-mail não saiu.")
      expect(row.text).to include("Reenviar e-mail")
    end
  end

  it "renaming another organization leaves the failure notice in place" do
    _account, sul = plant_coordinator(email: "sul@exemplo.org", organization_name: "ONG Sul")
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      raise_delivery
      post "/administration/confirm"
      follow_redirect!
      norte = Organization.find_by!(name: "ONG Norte")
      ActionMailer::Base.deliveries.clear
      post "/administration/name", params: { organization_id: sul.id }
      post "/administration/name/continue", params: { name: "ONG Sul Nova" }

      expect {
        post "/administration/name/confirm", params: { organization_id: sul.id }
      }.not_to change { ActionMailer::Base.deliveries.size }

      follow_redirect!
      expect(sul.reload.name).to eq("ONG Sul Nova")
      norte_row = organization_row(norte)
      expect(norte_row.at_css("[data-notice='error']").text).to include("O cadastro foi gravado, mas o e-mail não saiu.")
      expect(norte_row.text).to include("Reenviar e-mail")
      sul_row = organization_row(sul)
      expect(sul_row.text).to include("ONG Sul Nova")
      expect(sul_row.text).not_to include("E-mail enviado para")
      expect(sul_row.text).not_to include("O cadastro foi gravado")
    end
  end

  it "Corrigir on the name confirmation returns the typed name" do
    _account, organization = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration/name", params: { organization_id: organization.id }
      post "/administration/name/continue", params: { name: "ONG Norte Nova" }
      follow_administration
      expect(organization_row(organization).text).to include("Nenhum e-mail será enviado.")

      expect {
        post "/administration/correct"
      }.not_to change { organization.reload.name }

      follow_administration
      expect(ActionMailer::Base.deliveries).to be_empty
      expect(organization_row(organization).at_css('input[name="name"]')["value"]).to eq("ONG Norte Nova")
    end
  end

  it "name confirmation for a missing organization responds 404" do
    Organization.create!(name: "ONG Norte")
    missing_id = Organization.maximum(:id).to_i + 1
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration/name/confirm", params: { organization_id: missing_id }

      expect(response).to have_http_status(:not_found)
      expect(Organization.pluck(:name)).to eq([ "ONG Norte" ])
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  it "Corrigir nome discards an unwritten registration" do
    _account, existing = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      post "/administration", params: { name: "ONG Nova", email: "nova@exemplo.org" }
      expect(session[:administration_pending]["name"]).to eq("ONG Nova")

      post "/administration/name", params: { organization_id: existing.id }
      follow_administration

      expect(Organization.find_by(name: "ONG Nova")).to be_nil
      form = page.at_css('form[action="/administration"]')
      expect(form.at_css('input[name="name"]')["value"].to_s).to eq("")
      expect(form.at_css('input[name="email"]')["value"].to_s).to eq("")
      expect(organization_row(existing).at_css('input[name="name"]')["value"]).to eq("ONG Norte")
    end
  end

  it "a valid registration discards an open name field" do
    _account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      post "/administration/name", params: { organization_id: norte.id }
      session[:administration_name] = {
        "organization_id" => norte.id,
        "name" => "ONG Norte Nova",
        "confirming" => false
      }

      post "/administration", params: { name: "ONG Sul", email: "sul@exemplo.org" }
      follow_administration

      expect(norte.reload.name).to eq("ONG Norte")
      expect(page.at_css('form[action="/administration/confirm"]')).not_to be_nil
      expect(response.body).to include("ONG Sul")
      expect(response.body).to include("sul@exemplo.org")
      expect(organization_row(norte).at_css('input[name="name"]')).to be_nil
      expect(response.body).not_to include("Nenhum e-mail será enviado.")
    end
  end

  describe "concurrent confirms of the same name leave one organization" do
    self.use_transactional_tests = false

    it "concurrent confirms of the same name leave one organization" do
      truncate_product_tables
      ActionMailer::Base.deliveries.clear
      account = Account.create!(email: "seller@example.com", google_uid: "uid-seller")
      headers = { "User-Agent" => ChromeUserAgent::CHROME }

      with_env("ADMINISTRATOR_EMAIL" => "seller@example.com", "MAIL_FROM" => "venda@example.com") do
        session_a = signed_in_session(account)
        session_b = signed_in_session(account)
        session_a.post("/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }, headers: headers)
        session_b.post("/administration", params: { name: "ong norte", email: "coordenador@exemplo.org" }, headers: headers)

        threads = [ session_a, session_b ].map do |host|
          Thread.new { host.post("/administration/confirm", headers: headers) }
        end
        threads.each(&:join)

        loser = [ session_a, session_b ].find { |host| host.response.status == 422 }
        expect(Organization.where("lower((name)::text) = ?", "ong norte").count).to eq(1)
        expect(loser).not_to be_nil
        expect(loser.response.body).to include("Já existe uma organização com esse nome.")
        expect(loser.session[:administration_result]).to be_nil
        expect(Account.where(email: "coordenador@exemplo.org").count).to eq(1)
        expect(Access.where(account: Account.find_by!(email: "coordenador@exemplo.org")).count).to eq(1)
        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end
    ensure
      truncate_product_tables
      ActionMailer::Base.deliveries.clear
    end
  end

  describe "concurrent name confirms of the same name leave one rename" do
    self.use_transactional_tests = false

    it "concurrent name confirms of the same name leave one rename" do
      truncate_product_tables
      ActionMailer::Base.deliveries.clear
      account = Account.create!(email: "seller@example.com", google_uid: "uid-seller")
      norte = Organization.create!(name: "ONG Norte")
      sul = Organization.create!(name: "ONG Sul")
      headers = { "User-Agent" => ChromeUserAgent::CHROME }

      with_env("ADMINISTRATOR_EMAIL" => "seller@example.com", "MAIL_FROM" => "venda@example.com") do
        session_a = signed_in_session(account)
        session_b = signed_in_session(account)
        session_a.post("/administration/name", params: { organization_id: norte.id }, headers: headers)
        session_b.post("/administration/name", params: { organization_id: sul.id }, headers: headers)
        session_a.post("/administration/name/continue", params: { name: "ONG Iguais" }, headers: headers)
        session_b.post("/administration/name/continue", params: { name: "ONG Iguais" }, headers: headers)

        threads = [ [ session_a, norte.id ], [ session_b, sul.id ] ].map do |host, id|
          Thread.new { host.post("/administration/name/confirm", params: { organization_id: id }, headers: headers) }
        end
        threads.each(&:join)

        loser = [ session_a, session_b ].find { |host| host.response.status == 422 }
        names = Organization.order(:id).pluck(:name)
        expect(names.count("ONG Iguais")).to eq(1)
        expect([ "ONG Norte", "ONG Sul" ]).to include((names - [ "ONG Iguais" ]).first)
        expect(loser).not_to be_nil
        expect(loser.response.body).to include("Já existe uma organização com esse nome.")
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    ensure
      truncate_product_tables
      ActionMailer::Base.deliveries.clear
    end
  end
end
