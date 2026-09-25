require "rails_helper"

RSpec.describe "Administration", type: :request do
  def as_seller
    with_env("ADMINISTRATOR_EMAIL" => "seller@example.com", "MAIL_FROM" => "venda@example.com") do
      google_callback(email: "seller@example.com", uid: "uid-seller")
      yield
    end
  end

  def administration_routes
    [
      [ :get, "/administration" ],
      [ :post, "/administration" ],
      [ :post, "/administration/confirm" ],
      [ :post, "/administration/mail" ],
      [ :post, "/administration/another" ],
      [ :post, "/administration/name" ],
      [ :post, "/administration/name/continue" ],
      [ :post, "/administration/name/cancel" ],
      [ :post, "/administration/name/confirm" ],
      [ :post, "/administration/email" ],
      [ :post, "/administration/email/continue" ],
      [ :post, "/administration/email/cancel" ],
      [ :post, "/administration/email/confirm" ],
      [ :delete, "/administration" ]
    ]
  end

  def organization_row(organization)
    page.at_css("[data-organization-id='#{organization.id}']")
  end

  def page
    Nokogiri::HTML(response.body)
  end

  def administration_column
    column = page.css("main div").find { |node| node["class"].to_s.split.include?("max-w-[28rem]") }
    expect(column).not_to be_nil
    expect(column["class"]).not_to include("mx-auto")
    column
  end

  def expect_empty_form
    expect(response).to have_http_status(:ok)
    expect(page.at_css("h1").text.strip).to eq("Administração")
    expect(response.body).to include("Cadastre a organização e o coordenador que vai fechá-la.")
    expect(page.css("[data-notice='error']")).to be_empty
    column = page.at_css("main div")
    expect(column["class"]).to include("max-w-[28rem]")
    expect(column["class"]).not_to include("mx-auto")
    labels = page.css("label")
    expect(labels.map { |label| label.text.strip }).to eq([ "Nome da organização", "E-mail do coordenador" ])
    labels.each do |label|
      field = label.next_element
      expect(field.name).to eq("input")
      expect(field["value"].to_s).to eq("")
      %w[w-full border border-rule bg-sheet].each { |css| expect(field["class"]).to include(css) }
    end
    submit = page.at_css('input[type="submit"]')
    expect(submit["value"]).to eq("Continuar")
    expect(submit["class"]).to include("bg-caixa")
    expect(page.css("main svg")).to be_empty
    expect(page.css("h1, h2, h3").map { |heading| heading.text.strip }).to eq([ "Administração" ])
    expect(response.body).not_to include("Cadastrar outra organização")
  end

  def raise_delivery
    delivery = instance_double(ActionMailer::MessageDelivery)
    allow(CoordinatorWelcomeMailer).to receive(:welcome).and_return(delivery)
    allow(delivery).to receive(:deliver_now).and_raise(RuntimeError, "smtp down")
  end

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
      expect(group.css("button, a").map { |node| node.text.strip }).to eq([ "Confirmar", "Corrigir" ])
      confirm = group.at_css("button")
      expect(confirm["class"]).to include("bg-caixa")
      expect(confirm.ancestors("form").first["action"]).to eq("/administration/confirm")
      correct = group.at_css("a")
      expect(correct["href"]).to eq("/administration")
      expect(correct["class"]).to include("border")
      expect(correct["class"]).to include("border-ink")
      expect(session[:administration_pending]).to eq(
        "name" => "ONG Norte",
        "email" => "coordenador@exemplo.org"
      )
    end
  end

  it "confirmation column is 28rem and shows the record labels" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }

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

  it "GET /administration with pending fills the form" do
    sul = Organization.create!(name: "ONG Sul")
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      get "/administration"

      expect(response).to have_http_status(:ok)
      expect(page.at_css("h1").text.strip).to eq("Administração")
      expect(response.body).to include("Cadastre a organização e o coordenador que vai fechá-la.")
      expect(page.at_css('input[name="name"]')["value"]).to eq("ONG Norte")
      expect(page.at_css('input[name="email"]')["value"]).to eq("coordenador@exemplo.org")
      expect(page.at_css('form[action="/administration/confirm"]')).to be_nil
      expect(organization_row(sul).text).to include("Corrigir nome")
      expect(organization_row(sul).at_css('input[name="name"]')).to be_nil
    end
  end

  it "Corrigir on the registration confirmation returns the filled form" do
    sul = Organization.create!(name: "ONG Sul")
    as_seller do
      expect {
        post "/administration", params: { name: "  ONG Norte  ", email: " Coordenador@Exemplo.ORG " }
        get page.at_css('main a[href="/administration"]')["href"]
      }.not_to change { [ Organization.count, Account.count, Access.count ] }

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
      expect(group.css("button, a").map { |node| node.text.strip }).to eq([ "Confirmar", "Corrigir" ])
      confirm = group.at_css("button")
      expect(confirm["class"]).to include("bg-caixa")
      expect(confirm.ancestors("form").first["action"]).to eq("/administration/name/confirm")
      correct = group.at_css("a")
      expect(correct["href"]).to eq("/administration")
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
      expect(organization_row(organization).text).to include("Nenhum e-mail será enviado.")

      expect {
        get organization_row(organization).at_css('a[href="/administration"]')["href"]
      }.not_to change { organization.reload.name }

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

  it "GET /administration shows Corrigir on each coordinator email and Remover" do
    _account, sul = plant_coordinator(email: "sul@exemplo.org", organization_name: "ONG Sul", google_uid: "uid-sul")
    norte = Organization.create!(name: "ONG Norte")
    zoe = Account.create!(email: "zoe@exemplo.org")
    ana = Account.create!(email: "ana@exemplo.org")
    submitter = Account.create!(email: "submitter@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    Access.create!(account: ana, organization: norte, kind: :coordinator)
    Access.create!(account: submitter, organization: norte, kind: :submitter)

    as_seller do
      get "/administration"

      column = administration_column
      row = organization_row(norte)
      expect(column.css("[data-organization-id='#{norte.id}']").size).to eq(1)
      expect(row["class"]).to include("flex-wrap")
      buttons = row.css("button").map { |button| button.text.strip }
      expect(buttons).to include("Corrigir nome")
      expect(buttons.count("Corrigir")).to eq(2)
      expect(buttons).to include("Remover")
      html = row.inner_html
      expect(html.index("Corrigir nome")).to be < html.index("ana@exemplo.org")
      expect(html.index("ana@exemplo.org")).to be < html.index("zoe@exemplo.org")
      corrects = row.css("button").select { |button| button.text.strip == "Corrigir" }
      expect(corrects.size).to eq(2)
      corrects.each do |button|
        expect(button["class"]).to include("text-caixa")
        expect(button["class"]).to include("underline")
        expect(button["class"]).to include("underline-offset-2")
      end
      expect(html.index("ana@exemplo.org")).to be < html.index("zoe@exemplo.org")
      ana_correct = corrects.first
      expect(ana_correct.ancestors("form").first["action"]).to eq("/administration/email")
      remover = row.css("button").find { |button| button.text.strip == "Remover" }
      expect(remover["class"]).to include("text-margem")
      expect(remover["class"]).to include("underline")
      expect(remover["class"]).to include("underline-offset-2")
      expect(html.index("zoe@exemplo.org")).to be < html.index("Remover")
      form = remover.ancestors("form").first
      expect(form["data-turbo-confirm"]).to eq("Remover a organização ONG Norte?")
      expect(form["action"]).to eq("/administration")
      expect(form.at_css('input[name="_method"]')["value"]).to eq("delete")
      expect(response.body).not_to include("submitter@exemplo.org")
      expect(organization_row(sul).text).to include("Corrigir nome")
    end
  end

  it "Corrigir opens the coordinator email" do
    norte = Organization.create!(name: "ONG Norte")
    ana = Account.create!(email: "ana@exemplo.org")
    zoe = Account.create!(email: "zoe@exemplo.org")
    Access.create!(account: ana, organization: norte, kind: :coordinator)
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    as_seller do
      ActionMailer::Base.deliveries.clear
      expect {
        post "/administration/email", params: { organization_id: norte.id, email: "zoe@exemplo.org" }
      }.not_to change { [ Access.count, Account.count, ActionMailer::Base.deliveries.size ] }

      row = organization_row(norte)
      expect(row.text).to include("ONG Norte")
      field = row.at_css('input[type="email"]')
      expect(field["value"]).to eq("zoe@exemplo.org")
      submit = row.at_css('input[type="submit"]')
      expect(submit["value"]).to eq("Continuar")
      expect(submit["class"]).to include("bg-caixa")
      group = submit.parent
      expect(group["class"]).to include("flex-wrap")
      cancel = row.css("button").find { |button| button.text.strip == "Cancelar" }
      expect(cancel["class"]).to include("text-caixa")
      expect(cancel["class"]).to include("underline")
      expect(cancel["class"]).to include("underline-offset-2")
      expect(row.text).to include("ana@exemplo.org")
      expect(row.css("button").count { |button| button.text.strip == "Corrigir" }).to eq(1)
    end
  end

  it "Cancelar on the email field restores the row" do
    norte = Organization.create!(name: "ONG Norte")
    zoe = Account.create!(email: "zoe@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration/email", params: { organization_id: norte.id, email: "zoe@exemplo.org" }
      session[:administration_email]["email"] = "novo@exemplo.org"

      expect {
        post "/administration/email/cancel"
      }.not_to change { [ Access.count, Account.count ] }
      expect(ActionMailer::Base.deliveries).to be_empty

      follow_redirect!
      row = organization_row(norte)
      expect(row.text).to include("zoe@exemplo.org")
      expect(row.at_css('input[type="email"]')).to be_nil
    end
  end

  it "invalid email correction re-renders 422" do
    _account, norte = plant_coordinator(email: "zoe@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "zoe@exemplo.org" }
      expect {
        post "/administration/email/continue", params: { email: "nao-e-email" }
      }.not_to change(Access, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(page.css("[data-notice='error']").map { |notice| notice.text.strip }).to eq([
        "Informe um e-mail válido."
      ])
      expect(response.body.index("Administração")).to be < response.body.index("Informe um e-mail válido.")
      row = organization_row(norte)
      expect(row.at_css('input[name="email"]')["value"]).to eq("nao-e-email")
      expect(row.at_css('form[action="/administration/email/confirm"]')).to be_nil
    end
  end

  it "taken coordinator email correction re-renders 422" do
    norte = Organization.create!(name: "ONG Norte")
    ana = Account.create!(email: "ana@exemplo.org")
    zoe = Account.create!(email: "zoe@exemplo.org")
    Access.create!(account: ana, organization: norte, kind: :coordinator)
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "zoe@exemplo.org" }
      expect {
        post "/administration/email/continue", params: { email: "Ana@Exemplo.ORG" }
      }.not_to change(Access, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(page.css("[data-notice='error']").map { |notice| notice.text.strip }).to eq([
        "Esse e-mail já tem acesso a esta organização."
      ])
      expect(organization_row(norte).at_css('input[name="email"]')["value"]).to eq("Ana@Exemplo.ORG")
    end
  end

  it "taken submitter email correction re-renders 422" do
    _account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    plant_submitter(email: "submitter@exemplo.org", organization: norte)
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      expect {
        post "/administration/email/continue", params: { email: "submitter@exemplo.org" }
      }.not_to change(Access, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(page.css("[data-notice='error']").map { |notice| notice.text.strip }).to eq([
        "Esse e-mail já tem acesso a esta organização."
      ])
    end
  end

  it "the same coordinator email asks for confirmation" do
    _account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      expect {
        post "/administration/email/continue", params: { email: " Coordenador@Exemplo.ORG " }
      }.not_to change { [ Access.count, Account.count ] }

      expect(response).to have_http_status(:ok)
      expect(page.css("[data-notice='error']")).to be_empty
      row = organization_row(norte)
      expect(row.text).to include("ONG Norte")
      expect(row.text).to include("coordenador@exemplo.org")
      expect(row.text).not_to include("Esse e-mail já tem acesso a esta organização.")
    end
  end

  it "confirming the same coordinator email sends the welcome and writes no Access" do
    _account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      post "/administration/email/continue", params: { email: " Coordenador@Exemplo.ORG " }
      expect {
        post "/administration/email/confirm", params: { organization_id: norte.id }
      }.not_to change { norte.accesses.count }

      expect(Account.find_by!(email: "coordenador@exemplo.org").email).to eq("coordenador@exemplo.org")
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      message = ActionMailer::Base.deliveries.last
      expect(message.mime_type).to eq("text/plain")
      expect(message.to).to eq([ "coordenador@exemplo.org" ])
      expect(message.subject).to eq("Fechamento Mensal - Cadastro da Organização ONG Norte")
      expect(message.body.decoded).to eq(
        "A organização ONG Norte está pronta. Entre com o Google usando coordenador@exemplo.org, pelo botão Entrar com Google."
      )
      follow_redirect!
      expect(organization_row(norte).text).to include("E-mail enviado para coordenador@exemplo.org.")
    end
  end

  it "a new coordinator email asks for confirmation" do
    norte = Organization.create!(name: "ONG Norte")
    ana = Account.create!(email: "ana@exemplo.org")
    zoe = Account.create!(email: "zoe@exemplo.org")
    Access.create!(account: ana, organization: norte, kind: :coordinator)
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "zoe@exemplo.org" }
      expect {
        post "/administration/email/continue", params: { email: " Novo@Exemplo.ORG " }
      }.not_to change { [ Access.count, Account.count ] }

      expect(response).to have_http_status(:ok)
      row = organization_row(norte)
      expect(row.text).to include("ONG Norte")
      expect(row.text).to include("novo@exemplo.org")
      expect(row.text).not_to include("ana@exemplo.org")
      group = row.css("div").find { |node| node["class"].to_s.include?("flex-wrap") && node.text.include?("Confirmar") }
      expect(group.css("button, a").map { |node| node.text.strip }).to eq([ "Confirmar", "Corrigir" ])
    end
  end

  it "Corrigir on the email confirmation returns the typed email" do
    norte = Organization.create!(name: "ONG Norte")
    zoe = Account.create!(email: "zoe@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration/email", params: { organization_id: norte.id, email: "zoe@exemplo.org" }
      post "/administration/email/continue", params: { email: " Novo@Exemplo.ORG " }
      expect {
        get organization_row(norte).at_css('a[href="/administration"]')["href"]
      }.not_to change { [ Access.count, Account.count ] }

      expect(ActionMailer::Base.deliveries).to be_empty
      expect(organization_row(norte).at_css('input[name="email"]')["value"]).to eq("novo@exemplo.org")
    end
  end

  it "confirming a new coordinator email moves Access and sends the welcome" do
    norte = Organization.create!(name: "ONG Norte")
    sul = Organization.create!(name: "ONG Sul")
    old = Account.create!(email: "coordenador@exemplo.org")
    Access.create!(account: old, organization: norte, kind: :coordinator)
    Invite.create!(organization: norte, email: "novo@exemplo.org", kind: :coordinator)
    Invite.create!(organization: sul, email: "novo@exemplo.org", kind: :coordinator)
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      post "/administration/email/continue", params: { email: " Novo@Exemplo.ORG " }
      post "/administration/email/confirm", params: { organization_id: norte.id }

      expect(Account.find_by!(email: "novo@exemplo.org")).to be_present
      expect(old.reload.email).to eq("coordenador@exemplo.org")
      expect(norte.accesses.coordinator.count).to eq(1)
      expect(norte.accesses.coordinator.first.account.email).to eq("novo@exemplo.org")
      expect(Invite.find_by(organization: norte, email: "novo@exemplo.org")).to be_nil
      expect(Invite.find_by(organization: sul, email: "novo@exemplo.org")).to be_present
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      message = ActionMailer::Base.deliveries.last
      expect(message.mime_type).to eq("text/plain")
      expect(message.to).to eq([ "novo@exemplo.org" ])
      expect(message.subject).to eq("Fechamento Mensal - Cadastro da Organização ONG Norte")
      expect(message.body.decoded).to eq(
        "A organização ONG Norte está pronta. Entre com o Google usando novo@exemplo.org, pelo botão Entrar com Google."
      )
      expect(ActionMailer::Base.deliveries.map { |mail| mail.body.decoded }.join).not_to include("Você foi convidado")
      follow_redirect!
      expect(organization_row(norte).text).to include("E-mail enviado para novo@exemplo.org.")
    end
  end

  it "moving Access onto an existing coordinator Account keeps Account.count" do
    _sul_account, _sul = plant_coordinator(email: "sul@exemplo.org", organization_name: "ONG Sul")
    norte = Organization.create!(name: "ONG Norte")
    old = Account.create!(email: "coordenador@exemplo.org")
    Access.create!(account: old, organization: norte, kind: :coordinator)
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      post "/administration/email/continue", params: { email: "sul@exemplo.org" }
      expect {
        post "/administration/email/confirm", params: { organization_id: norte.id }
      }.not_to change(Account, :count)

      expect(old.reload.email).to eq("coordenador@exemplo.org")
      expect(norte.accesses.coordinator.first.account.email).to eq("sul@exemplo.org")
      expect(ActionMailer::Base.deliveries.last.body.decoded).to eq(
        "A organização ONG Norte foi adicionada à sua conta. Entre com o Google usando sul@exemplo.org, pelo botão Entrar com Google."
      )
    end
  end

  it "the welcome after an email move addresses the new email" do
    norte = Organization.create!(name: "ONG Norte")
    ana = Account.create!(email: "ana@exemplo.org")
    zoe = Account.create!(email: "zoe@exemplo.org")
    Access.create!(account: ana, organization: norte, kind: :coordinator)
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration/email", params: { organization_id: norte.id, email: "zoe@exemplo.org" }
      post "/administration/email/continue", params: { email: "novo@exemplo.org" }
      post "/administration/email/confirm", params: { organization_id: norte.id }

      expect(norte.accesses.coordinator.joins(:account).pluck("accounts.email")).to contain_exactly(
        "ana@exemplo.org", "novo@exemplo.org"
      )
      expect(ActionMailer::Base.deliveries.last.to).to eq([ "novo@exemplo.org" ])
    end
  end

  it "email confirm keeps the move when deliver_now raises" do
    norte = Organization.create!(name: "ONG Norte")
    sul = Organization.create!(name: "ONG Sul")
    old = Account.create!(email: "coordenador@exemplo.org")
    Access.create!(account: old, organization: norte, kind: :coordinator)
    Invite.create!(organization: norte, email: "novo@exemplo.org", kind: :coordinator)
    Invite.create!(organization: sul, email: "novo@exemplo.org", kind: :coordinator)
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      post "/administration/email/continue", params: { email: "novo@exemplo.org" }
      raise_delivery
      post "/administration/email/confirm", params: { organization_id: norte.id }

      expect(Account.find_by(email: "novo@exemplo.org")).to be_present
      expect(norte.accesses.coordinator.first.account.email).to eq("novo@exemplo.org")
      expect(Access.find_by(account: old, organization: norte)).to be_nil
      expect(old.reload.email).to eq("coordenador@exemplo.org")
      expect(Invite.find_by(organization: norte, email: "novo@exemplo.org")).to be_nil
      follow_redirect!
      row = organization_row(norte)
      expect(row.at_css("[data-notice='error']").text.strip).to eq("A correção foi gravada, mas o e-mail não saiu.")
      resend = row.css("button").find { |button| button.text.strip == "Reenviar e-mail" }
      expect(resend["class"]).to include("bg-caixa")
      expect(resend.ancestors("form").first["action"]).to eq("/administration/mail")
      expect(response.body).not_to include("E-mail enviado para")
    end
  end

  it "correction resend delivers to the new email" do
    norte = Organization.create!(name: "ONG Norte")
    ana = Account.create!(email: "ana@exemplo.org")
    zoe = Account.create!(email: "zoe@exemplo.org")
    Access.create!(account: ana, organization: norte, kind: :coordinator)
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "zoe@exemplo.org" }
      post "/administration/email/continue", params: { email: "novo@exemplo.org" }
      raise_delivery
      post "/administration/email/confirm", params: { organization_id: norte.id }
      allow(CoordinatorWelcomeMailer).to receive(:welcome).and_call_original
      ActionMailer::Base.deliveries.clear
      post "/administration/mail"

      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(ActionMailer::Base.deliveries.last.to).to eq([ "novo@exemplo.org" ])
      expect(ActionMailer::Base.deliveries.last.subject).to eq("Fechamento Mensal - Cadastro da Organização ONG Norte")
      follow_redirect!
      expect(organization_row(norte).text).to include("E-mail enviado para novo@exemplo.org.")
      expect(organization_row(norte).text).not_to include("Reenviar e-mail")
    end
  end

  it "correction resend keeps the correction notice when deliver_now raises" do
    norte = Organization.create!(name: "ONG Norte")
    old = Account.create!(email: "coordenador@exemplo.org")
    Access.create!(account: old, organization: norte, kind: :coordinator)
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      post "/administration/email/continue", params: { email: "novo@exemplo.org" }
      raise_delivery
      post "/administration/email/confirm", params: { organization_id: norte.id }
      accesses = Access.order(:id).pluck(:id, :account_id, :organization_id)
      post "/administration/mail"

      expect(Access.order(:id).pluck(:id, :account_id, :organization_id)).to eq(accesses)
      follow_redirect!
      expect(organization_row(norte).at_css("[data-notice='error']").text.strip).to eq(
        "A correção foi gravada, mas o e-mail não saiu."
      )
    end
  end

  it "confirm of the signed-in email on a correction focuses the organization" do
    norte = Organization.create!(name: "ONG Norte")
    old = Account.create!(email: "coordenador@exemplo.org")
    Access.create!(account: old, organization: norte, kind: :coordinator)
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      post "/administration/email/continue", params: { email: "seller@example.com" }
      post "/administration/email/confirm", params: { organization_id: norte.id }

      expect(session[:organization_id]).to eq(norte.id)
    end
  end

  it "confirm of another email on a correction leaves the focused organization" do
    _account, previous = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Sul",
      google_uid: "uid-seller"
    )
    norte = Organization.create!(name: "ONG Norte")
    old = Account.create!(email: "coordenador@exemplo.org")
    Access.create!(account: old, organization: norte, kind: :coordinator)
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      post "/administration/email/continue", params: { email: "novo@exemplo.org" }
      post "/administration/email/confirm", params: { organization_id: norte.id }

      expect(session[:organization_id]).to eq(previous.id)
    end
  end

  it "email confirmation for a missing organization responds 404" do
    Organization.create!(name: "ONG Norte")
    missing_id = Organization.maximum(:id).to_i + 1
    as_seller do
      ActionMailer::Base.deliveries.clear
      expect {
        post "/administration/email/confirm", params: { organization_id: missing_id }
      }.not_to change(Access, :count)

      expect(response).to have_http_status(:not_found)
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  it "Corrigir on an email discards an unwritten name confirmation" do
    _account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      post "/administration/name", params: { organization_id: norte.id }
      post "/administration/name/continue", params: { name: "ONG Norte Nova" }
      expect(organization_row(norte).text).to include("Nenhum e-mail será enviado.")

      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }

      expect(norte.reload.name).to eq("ONG Norte")
      expect(response.body).not_to include("Nenhum e-mail será enviado.")
      expect(organization_row(norte).at_css('input[name="email"]')["value"]).to eq("coordenador@exemplo.org")
    end
  end

  it "Corrigir nome discards an unwritten email confirmation" do
    _account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      post "/administration/email/continue", params: { email: "novo@exemplo.org" }
      expect(organization_row(norte).text).to include("novo@exemplo.org")

      expect {
        post "/administration/name", params: { organization_id: norte.id }
      }.not_to change(Access, :count)

      expect(ActionMailer::Base.deliveries).to be_empty
      expect(organization_row(norte).text).not_to include("novo@exemplo.org")
      expect(organization_row(norte).at_css('input[name="name"]')["value"]).to eq("ONG Norte")
    end
  end

  it "a valid registration discards an unwritten email confirmation" do
    _account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      post "/administration/email/continue", params: { email: "novo@exemplo.org" }

      expect {
        post "/administration", params: { name: "ONG Sul", email: "sul@exemplo.org" }
      }.not_to change(Access, :count)

      expect(ActionMailer::Base.deliveries).to be_empty
      expect(page.at_css('form[action="/administration/confirm"]')).not_to be_nil
      expect(organization_row(norte).text).not_to include("novo@exemplo.org")
    end
  end

  it "removing an organization with no close data deletes it" do
    norte = Organization.create!(
      name: "ONG Norte",
      accountant_presentation_name: "Ana Contábil",
      package_archive_folder_id: "folder-norte",
      sefaz_pkcs12_ciphertext: "cipher"
    )
    coordinator = Account.create!(email: "coordenador@exemplo.org")
    submitter = Account.create!(email: "submitter@exemplo.org")
    Access.create!(account: coordinator, organization: norte, kind: :coordinator)
    Access.create!(account: submitter, organization: norte, kind: :submitter)
    Invite.create!(organization: norte, email: "pessoa@exemplo.org", kind: :coordinator)
    as_seller do
      delete "/administration", params: { organization_id: norte.id }

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to("/administration")
      expect(Organization.find_by(id: norte.id)).to be_nil
      expect(Access.where(organization_id: norte.id)).to be_empty
      expect(Invite.where(organization_id: norte.id)).to be_empty
      expect(Account.find_by(id: coordinator.id)).to eq(coordinator)
      expect(Account.find_by(id: submitter.id)).to eq(submitter)
      follow_redirect!
      expect(response.body).not_to include("ONG Norte")
    end
  end

  it "GET /administration after removing the focused organization keeps the session id" do
    account, norte = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Norte",
      google_uid: "uid-seller"
    )
    as_seller do
      expect(session[:organization_id]).to eq(norte.id)
      deleted_id = norte.id
      delete "/administration", params: { organization_id: norte.id }
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(session[:organization_id]).to eq(deleted_id)
      expect(page.at_css("header").text).to include("Fechamento mensal")
      expect(account.reload).to eq(account)
    end
  end

  it "removing another organization leaves the focused organization" do
    _account, sul = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Sul",
      google_uid: "uid-seller"
    )
    norte = Organization.create!(name: "ONG Norte")
    other = Account.create!(email: "coordenador@exemplo.org")
    Access.create!(account: other, organization: norte, kind: :coordinator)
    as_seller do
      expect(session[:organization_id]).to eq(sul.id)
      delete "/administration", params: { organization_id: norte.id }
      follow_redirect!

      expect(session[:organization_id]).to eq(sul.id)
      expect(page.at_css("header").text).to include("ONG Sul")
    end
  end

  it "removing an organization with a BankAccount re-renders 422" do
    _account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    BankAccount.create_for(organization: norte, name: "Conta Principal", compe: "001")
    as_seller do
      expect {
        delete "/administration", params: { organization_id: norte.id }
      }.not_to change { [ Organization.count, Access.count, Invite.count, BankAccount.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      notice = organization_row(norte).at_css("[data-notice='error']")
      expect(notice.text.strip).to eq("Esta organização já tem dados de fechamento e não pode ser removida.")
    end
  end

  it "removing an organization with a Month re-renders 422" do
    _account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    Month.open(organization: norte, year_month: "2026-05")
    as_seller do
      expect {
        delete "/administration", params: { organization_id: norte.id }
      }.not_to change { [ Organization.count, Access.count, Month.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(organization_row(norte).at_css("[data-notice='error']").text.strip).to eq(
        "Esta organização já tem dados de fechamento e não pode ser removida."
      )
    end
  end

  it "removing an organization with a SupportingDocument re-renders 422" do
    account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    SupportingDocument.create!(
      organization: norte,
      account: account,
      kind: "recibo",
      amount_cents: 100,
      document_on: Date.new(2026, 5, 11),
      payee: "Padaria"
    )
    as_seller do
      expect {
        delete "/administration", params: { organization_id: norte.id }
      }.not_to change { [ Organization.count, Access.count, SupportingDocument.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(organization_row(norte).at_css("[data-notice='error']").text.strip).to eq(
        "Esta organização já tem dados de fechamento e não pode ser removida."
      )
    end
  end

  it "removing an organization with a Justification re-renders 422" do
    account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    Justification.create!(organization: norte, account: account, amount_cents: 100)
    as_seller do
      expect {
        delete "/administration", params: { organization_id: norte.id }
      }.not_to change { [ Organization.count, Access.count, Justification.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(organization_row(norte).at_css("[data-notice='error']").text.strip).to eq(
        "Esta organização já tem dados de fechamento e não pode ser removida."
      )
    end
  end

  it "removing an organization with an ExtraExceptionKind re-renders 422" do
    _account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    ExtraExceptionKind.create_for(organization: norte, name: "Doação")
    as_seller do
      expect {
        delete "/administration", params: { organization_id: norte.id }
      }.not_to change { [ Organization.count, Access.count, ExtraExceptionKind.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(organization_row(norte).at_css("[data-notice='error']").text.strip).to eq(
        "Esta organização já tem dados de fechamento e não pode ser removida."
      )
    end
  end

  it "removing a missing organization responds 404" do
    kept = Organization.create!(name: "ONG Sul")
    missing_id = Organization.maximum(:id).to_i + 1
    as_seller do
      delete "/administration", params: { organization_id: missing_id }

      expect(response).to have_http_status(:not_found)
      expect(Organization.find(kept.id)).to eq(kept)
    end
  end

  it "GET /administration after removing the result organization shows the empty form" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      post "/administration/confirm"
      norte = Organization.find_by!(name: "ONG Norte")
      delete "/administration", params: { organization_id: norte.id }
      get "/administration"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cadastre a organização e o coordenador que vai fechá-la.")
      expect(response.body).not_to include("ONG Norte")
      expect(response.body).not_to include("E-mail enviado para")
      expect(response.body).not_to include("O cadastro foi gravado, mas o e-mail não saiu.")
    end
  end

  it "resend for a missing result organization redirects and delivers nothing" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      post "/administration/confirm"
      norte = Organization.find_by!(name: "ONG Norte")
      norte.remove
      ActionMailer::Base.deliveries.clear
      expect {
        post "/administration/mail"
      }.not_to change { [ Organization.count, Account.count, Access.count, ActionMailer::Base.deliveries.size ] }

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to("/administration")
    end
  end
end
