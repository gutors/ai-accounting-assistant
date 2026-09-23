require "rails_helper"

RSpec.describe "Administration intake", type: :request do
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
      [ :post, "/administration/another" ]
    ]
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
  end

  def raise_delivery
    delivery = instance_double(ActionMailer::MessageDelivery)
    allow(CoordinatorWelcomeMailer).to receive(:welcome).and_return(delivery)
    allow(delivery).to receive(:deliver_now).and_raise(RuntimeError, "smtp down")
  end

  it "signed-out administration routes redirect to /login" do
    expect {
      administration_routes.each do |verb, path|
        public_send(verb, path, params: { name: "ONG Norte", email: "coordenador@exemplo.org" })
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to("/login")
      end
    }.not_to change { [ Organization.count, Account.count, Access.count ] }
  end

  it "non-administrator and blank allowlist administration routes respond 404" do
    account, organization = plant_coordinator(email: "other@example.com", organization_name: "ONG Sul")
    sign_in_as(account, organization: organization)

    [ "seller@example.com", nil, "" ].each do |allow|
      with_env("ADMINISTRATOR_EMAIL" => allow) do
        administration_routes.each do |verb, path|
          expect {
            public_send(verb, path, params: { name: "ONG Norte", email: "coordenador@exemplo.org" })
          }.not_to change { [ Organization.count, Account.count, Access.count ] }
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
    as_seller do
      expect {
        post "/administration", params: { name: "   ", email: "coordenador@exemplo.org" }
      }.not_to change { [ Organization.count, Account.count, Access.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      notices = page.css("[data-notice='error']").map { |notice| notice.text.strip }
      expect(notices).to eq([ "Informe o nome da organização." ])
      expect(page.at_css('input[name="name"]')["value"]).to eq("   ")
      expect(page.at_css('input[name="email"]')["value"]).to eq("coordenador@exemplo.org")
      expect(session[:administration_pending]).to be_nil
    end
  end

  it "invalid coordinator email re-renders 422 and writes nothing" do
    as_seller do
      expect {
        post "/administration", params: { name: "ONG Norte", email: "nao-e-email" }
      }.not_to change { [ Organization.count, Account.count, Access.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      notices = page.css("[data-notice='error']").map { |notice| notice.text.strip }
      expect(notices).to eq([ "Informe um e-mail válido." ])
      expect(page.at_css('input[name="name"]')["value"]).to eq("ONG Norte")
      expect(page.at_css('input[name="email"]')["value"]).to eq("nao-e-email")
      expect(session[:administration_pending]).to be_nil
    end
  end

  it "blank name and invalid email re-render both notices" do
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
      expect(session[:administration_pending]).to be_nil
    end
  end

  it "valid POST stores pending and renders confirmation" do
    as_seller do
      expect {
        post "/administration", params: { name: "  ONG Norte  ", email: " Coordenador@Exemplo.ORG " }
      }.not_to change { [ Organization.count, Account.count, Access.count ] }

      expect(response).to have_http_status(:ok)
      expect(page.at_css("h1").text.strip).to eq("Confirmar cadastro")
      expect(response.body).to include("ONG Norte")
      expect(response.body).to include("coordenador@exemplo.org")
      expect(response.body).not_to include("Cadastre a organização e o coordenador que vai fechá-la.")
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
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      get "/administration"

      expect(response).to have_http_status(:ok)
      expect(page.at_css("h1").text.strip).to eq("Administração")
      expect(page.at_css('input[name="name"]')["value"]).to eq("ONG Norte")
      expect(page.at_css('input[name="email"]')["value"]).to eq("coordenador@exemplo.org")
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
        "mail_sent" => true
      )
      expect(ActionMailer::Base.deliveries.size).to eq(1)

      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(page.at_css("h1").text.strip).to eq("Administração")
      expect(response.body).to include("E-mail enviado para coordenador@exemplo.org.")
      expect(response.body).not_to include("Cadastre a organização e o coordenador que vai fechá-la.")
      column = administration_column
      sentence = column.css("p").find { |node| node.text.include?("E-mail enviado para coordenador@exemplo.org.") }
      expect(sentence).not_to be_nil
      ruled = sentence.next_element
      expect(ruled["class"]).to include("border-b")
      expect(ruled["class"]).to include("border-rule")
      expect(ruled.text).not_to include("E-mail enviado para")
      expect(ruled.text).to include("Nome da organização")
      expect(ruled.text).to include("ONG Norte")
      email_row = ruled.next_element
      expect(email_row.text).to include("E-mail do coordenador")
      expect(email_row.text).to include("coordenador@exemplo.org")
      expect(email_row.text).not_to include("E-mail enviado para")
      expect(page.css("[data-notice='error']")).to be_empty
      button = page.at_css("main button")
      expect(button.text.strip).to eq("Cadastrar outra organização")
      expect(button["class"]).to include("border")
      expect(button["class"]).to include("border-ink")
      expect(button.ancestors("form").first["action"]).to eq("/administration/another")
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
      expect(response.body).to include("E-mail enviado para coordenador@exemplo.org.")
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
      }.not_to change { [ Organization.count, Account.count, Access.count ] }

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to("/administration")
      expect(session[:administration_result]).to eq(result)
    end
  end

  it "confirm keeps the rows when deliver_now raises" do
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
        "mail_sent" => false
      )
      expect(response).to redirect_to("/administration")

      follow_redirect!
      expect(page.at_css("h1").text.strip).to eq("Administração")
      column = administration_column
      notice = column.at_css("[data-notice='error']")
      expect(notice.text.strip).to eq("O cadastro foi gravado, mas o e-mail não saiu.")
      expect(response.body.index("Administração")).to be < response.body.index(notice.text.strip)
      ruled = notice.next_element
      expect(ruled["class"]).to include("border-b")
      expect(ruled["class"]).to include("border-rule")
      expect(response.body).not_to include("E-mail enviado para")
      group = page.at_css("main .flex-wrap")
      expect(group.css("button").map { |button| button.text.strip }).to eq([
        "Reenviar e-mail",
        "Cadastrar outra organização"
      ])
      resend = group.css("button").first
      other = group.css("button").last
      expect(resend["class"]).to include("bg-caixa")
      expect(resend.ancestors("form").first["action"]).to eq("/administration/mail")
      expect(other["class"]).to include("border")
      expect(other["class"]).to include("border-ink")
      expect(other.ancestors("form").first["action"]).to eq("/administration/another")
    end
  end

  it "mail failure shows the saved record" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      raise_delivery
      post "/administration/confirm"
      follow_redirect!

      column = administration_column
      notice = column.at_css("[data-notice='error']")
      ruled = notice.next_element
      expect(ruled["class"]).to include("border-b")
      expect(ruled["class"]).to include("border-rule")
      expect(ruled.text).to include("Nome da organização")
      expect(ruled.text).to include("ONG Norte")
      email_row = ruled.next_element
      expect(email_row.text).to include("E-mail do coordenador")
      expect(email_row.text).to include("coordenador@exemplo.org")
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
      expect(response.body).to include("E-mail enviado para coordenador@exemplo.org.")
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
      expect(response.body).to include("O cadastro foi gravado, mas o e-mail não saiu.")
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
      expect_empty_form
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

  it "saved registration screens have no name or email fields" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      raise_delivery
      post "/administration/confirm"
      follow_redirect!

      expect(page.at_css('input[name="name"]')).to be_nil
      expect(page.at_css('input[name="email"]')).to be_nil
      expect(Organization.find_by!(name: "ONG Norte").name).to eq("ONG Norte")
      expect(Account.find_by!(email: "coordenador@exemplo.org").email).to eq("coordenador@exemplo.org")

      allow(CoordinatorWelcomeMailer).to receive(:welcome).and_call_original
      post "/administration/mail"
      follow_redirect!

      expect(page.at_css('input[name="name"]')).to be_nil
      expect(page.at_css('input[name="email"]')).to be_nil
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
end
