require "rails_helper"

RSpec.describe "Administration access", type: :request do
  include AdministrationHelpers

  it "GET /administration lists the principal coordinator email Status and Editar" do
    _account, sul = plant_coordinator(email: "sul@exemplo.org", organization_name: "ONG Sul", google_uid: "uid-sul")
    zoe = Account.create!(email: "zoe@exemplo.org")
    norte = create_organization!(name: "ONG Norte", principal_coordinator_account: zoe)
    ana = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")
    submitter = Account.create!(email: "submitter@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    Access.create!(account: ana, organization: norte, kind: :coordinator)
    Access.create!(account: submitter, organization: norte, kind: :submitter)

    as_seller do
      get "/administration"

      expect(response).to have_http_status(:ok)
      expect(page.at_css("h1").text.strip).to eq("Administração")
      add = page.css("a").find { |link| link.text.strip == "Adicionar organização" }
      expect(add["href"]).to eq("/administration/new")
      expect(add["class"]).to include("bg-caixa")
      header_row = page.css("div").find { |div|
        div["class"].to_s.include?("md:grid-cols-") && div.css("p").map { |p| p.text.strip } == [
          "Nome", "Email coordenador", "Status", "Editar"
        ]
      }
      expect(header_row).not_to be_nil
      row = organization_row(norte)
      expect(row.css("a").find { |link| link.text.strip == "Editar" }["href"]).to eq("/administration/#{norte.id}/edit")
      editar = row.css("a").find { |link| link.text.strip == "Editar" }
      expect(editar["class"]).to include("text-caixa")
      expect(editar["class"]).to include("underline")
      expect(editar["class"]).to include("underline-offset-2")
      expect(row.text).to include("ONG Norte")
      expect(row.text).to include("zoe@exemplo.org")
      expect(row.text).to include("Pendente")
      expect(row.text).not_to include("ana@exemplo.org")
      expect(row.text).not_to include("Corrigir")
      expect(row.text).not_to include("Remover")
      expect(response.body).not_to include("submitter@exemplo.org")
      expect(organization_row(sul).text).to include("Ativa")
    end
  end

  it "GET /administration Status is Ativa when the principal has google_uid" do
    zoe = Account.create!(email: "zoe@exemplo.org", google_uid: "uid-zoe")
    norte = create_organization!(name: "ONG Norte", principal_coordinator_account: zoe)
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    ana = Account.create!(email: "ana@exemplo.org")
    Access.create!(account: ana, organization: norte, kind: :coordinator)

    as_seller do
      get "/administration"

      expect(organization_row(norte).text).to include("Ativa")
    end
  end

  it "GET /administration/:id/edit shows Corrigir only on the principal email" do
    plant_coordinator(email: "sul@exemplo.org", organization_name: "ONG Sul", google_uid: "uid-sul")
    zoe = Account.create!(email: "zoe@exemplo.org")
    norte = create_organization!(name: "ONG Norte", principal_coordinator_account: zoe)
    ana = Account.create!(email: "ana@exemplo.org")
    submitter = Account.create!(email: "submitter@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    Access.create!(account: ana, organization: norte, kind: :coordinator)
    Access.create!(account: submitter, organization: norte, kind: :submitter)

    as_seller do
      get "/administration/#{norte.id}/edit"

      expect(response).to have_http_status(:ok)
      row = organization_row(norte)
      expect(row.css("p, button").map { |node| node.text.strip }).to eq([
        "Nome da organização",
        "ONG Norte",
        "Corrigir nome",
        "E-mail do coordenador principal",
        "zoe@exemplo.org",
        "Corrigir",
        "Outros coordenadores",
        "ana@exemplo.org",
        "Remover"
      ])
      corrects = row.css("button").select { |button| button.text.strip == "Corrigir" }
      expect(corrects.size).to eq(1)
      expect(corrects.first["class"]).to include("text-caixa")
      expect(corrects.first["class"]).to include("underline")
      expect(corrects.first["class"]).to include("underline-offset-2")
      expect(corrects.first.ancestors("form").first.at_css('input[name="email"]')["value"]).to eq("zoe@exemplo.org")
      remover = row.css("button").find { |button| button.text.strip == "Remover" }
      expect(remover["class"]).to include("text-margem")
      expect(remover["class"]).to include("underline")
      expect(remover["class"]).to include("underline-offset-2")
      form = remover.ancestors("form").first
      expect(form["data-turbo-confirm"]).to eq("Remover a organização ONG Norte?")
      expect(response.body).not_to include("submitter@exemplo.org")
    end
  end

  it "Corrigir opens the coordinator email" do
    zoe = Account.create!(email: "zoe@exemplo.org")
    norte = create_organization!(name: "ONG Norte", principal_coordinator_account: zoe)
    ana = Account.create!(email: "ana@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    Access.create!(account: ana, organization: norte, kind: :coordinator)
    as_seller do
      ActionMailer::Base.deliveries.clear
      expect {
        post "/administration/email", params: { organization_id: norte.id, email: "zoe@exemplo.org" }
      }.not_to change { [ Access.count, Account.count, ActionMailer::Base.deliveries.size ] }

      follow_administration("/administration/#{norte.id}/edit")
      row = organization_row(norte)
      expect(row.text).to include("ONG Norte")
      expect(row.css("p").map { |node| node.text.strip }).to include("Nome da organização")
      field = row.at_css('input[type="email"]')
      expect(field["value"]).to eq("zoe@exemplo.org")
      expect(row.at_css("label[for='#{field['id']}']").text.strip).to eq("E-mail do coordenador principal")
      submit = row.at_css('input[type="submit"]')
      expect(submit["value"]).to eq("Continuar")
      expect(submit["class"]).to include("bg-caixa")
      group = submit.parent
      expect(group["class"]).to include("flex-wrap")
      expect(group.css("input[type='submit'], button").map { |node| node["value"] || node.text.strip }).to eq([
        "Continuar", "Cancelar"
      ])
      cancel = row.css("button").find { |button| button.text.strip == "Cancelar" }
      expect(cancel["class"]).to include("text-caixa")
      expect(cancel["class"]).to include("underline")
      expect(cancel["class"]).to include("underline-offset-2")
      expect(row.text).to include("ana@exemplo.org")
      expect(row.css("p").map { |node| node.text.strip }).to include("Outros coordenadores")
      expect(row.css("button").count { |button| button.text.strip == "Corrigir" }).to eq(0)
    end
  end

  it "Cancelar on the email field restores the row" do
    norte = create_organization!(name: "ONG Norte")
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

  it "invalid principal email correction re-renders 422" do
    _account, norte = plant_coordinator(email: "zoe@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "zoe@exemplo.org" }
      expect {
        post "/administration/email/continue", params: { email: "nao-e-email" }
      }.not_to change(Access, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(page.at_css("h1").text.strip).to eq("Editar organização")
      expect(page.css("[data-notice='error']").map { |notice| notice.text.strip }).to eq([
        "Informe um e-mail válido."
      ])
      expect(response.body.index("Editar organização")).to be < response.body.index("Informe um e-mail válido.")
      row = organization_row(norte)
      expect(row.at_css('input[name="email"]')["value"]).to eq("nao-e-email")
      expect(row.at_css('form[action="/administration/email/confirm"]')).to be_nil
    end
  end

  it "taken peer coordinator email correction re-renders 422" do
    zoe = Account.create!(email: "zoe@exemplo.org")
    norte = create_organization!(name: "ONG Norte", principal_coordinator_account: zoe)
    ana = Account.create!(email: "ana@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    Access.create!(account: ana, organization: norte, kind: :coordinator)
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

  it "Continuar on a same-org submitter email is not a collision" do
    _account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    plant_submitter(email: "submitter@exemplo.org", organization: norte)
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      expect {
        post "/administration/email/continue", params: { email: " Submitter@Exemplo.ORG " }
      }.not_to change(Access, :count)

      expect(response).not_to have_http_status(:unprocessable_content)
      expect(response.body).not_to include("Esse e-mail já tem acesso a esta organização.")
    end
  end

  it "confirming a same-org submitter promotes Access and sends no welcome" do
    coordinator, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    submitter, _ = plant_submitter(email: "submitter@exemplo.org", organization: norte)
    Invite.insert_all!([ {
      organization_id: norte.id,
      email: "submitter@exemplo.org",
      kind: "coordinator",
      created_at: Time.current,
      updated_at: Time.current
    } ])
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      post "/administration/email/continue", params: { email: " Submitter@Exemplo.ORG " }
      expect {
        post "/administration/email/confirm", params: { organization_id: norte.id }
      }.not_to change(Account, :count)

      expect(norte.accesses.find_by!(account: submitter).kind).to eq("coordinator")
      expect(norte.reload.principal_coordinator_account).to eq(submitter)
      expect(Access.find_by(account: coordinator, organization: norte)).to be_nil
      expect(Invite.find_by(organization: norte, email: "submitter@exemplo.org")).to be_nil
      expect(ActionMailer::Base.deliveries).to be_empty
      follow_redirect!
      get "/administration"
      expect(organization_row(norte).text).to include("submitter@exemplo.org")
      expect(organization_row(norte).text).not_to include("E-mail enviado para")
      expect(organization_row(norte).text).not_to include("A correção foi gravada, mas o e-mail não saiu.")
    end
  end

  it "POST /administration/email for a non-principal coordinator returns 404" do
    zoe = Account.create!(email: "zoe@exemplo.org")
    norte = create_organization!(name: "ONG Norte", principal_coordinator_account: zoe)
    ana = Account.create!(email: "ana@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    Access.create!(account: ana, organization: norte, kind: :coordinator)
    as_seller do
      expect {
        post "/administration/email", params: { organization_id: norte.id, email: "ana@exemplo.org" }
      }.not_to change(Access, :count)

      expect(response).to have_http_status(:not_found)
      expect(response.body).to eq("")
    end
  end

  it "the same coordinator email asks for confirmation" do
    _account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      expect {
        post "/administration/email/continue", params: { email: " Coordenador@Exemplo.ORG " }
      }.not_to change { [ Access.count, Account.count ] }

      follow_administration("/administration/#{norte.id}/edit")
      expect(response).to have_http_status(:ok)
      expect(page.css("[data-notice='error']")).to be_empty
      row = organization_row(norte)
      expect(row.text).to include("ONG Norte")
      expect(row.text).to include("coordenador@exemplo.org")
      expect(row.text).not_to include("Esse e-mail já tem acesso a esta organização.")
    end
  end

  it "confirming the current principal email writes nothing and sends nothing" do
    _account, norte = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      post "/administration/email/continue", params: { email: " Coordenador@Exemplo.ORG " }
      expect {
        post "/administration/email/confirm", params: { organization_id: norte.id }
      }.not_to change { [ norte.accesses.count, Access.order(:id).pluck(:id, :account_id, :kind) ] }

      expect(ActionMailer::Base.deliveries).to be_empty
      follow_redirect!
      expect(organization_row(norte).text).to include("coordenador@exemplo.org")
      expect(organization_row(norte).text).not_to include("E-mail enviado para")
    end
  end

  it "a new coordinator email asks for confirmation" do
    zoe = Account.create!(email: "zoe@exemplo.org")
    norte = create_organization!(name: "ONG Norte", principal_coordinator_account: zoe)
    ana = Account.create!(email: "ana@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    Access.create!(account: ana, organization: norte, kind: :coordinator)
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "zoe@exemplo.org" }
      expect {
        post "/administration/email/continue", params: { email: " Novo@Exemplo.ORG " }
      }.not_to change { [ Access.count, Account.count ] }

      follow_administration("/administration/#{norte.id}/edit")
      expect(response).to have_http_status(:ok)
      row = organization_row(norte)
      html = row.inner_html
      expect(html.index("Nome da organização")).to be < html.index("ONG Norte")
      expect(html.index("ONG Norte")).to be < html.index("E-mail do coordenador principal")
      expect(html.index("E-mail do coordenador principal")).to be < html.index("novo@exemplo.org")
      name_label = row.css("p").find { |node| node.text.strip == "Nome da organização" }
      expect(name_label.next_element.text.strip).to eq("ONG Norte")
      email_label = row.css("p").find { |node| node.text.strip == "E-mail do coordenador principal" }
      expect(email_label.next_element.text.strip).to eq("novo@exemplo.org")
      expect(row.text).not_to include("ana@exemplo.org")
      group = row.css("div").find { |node| node["class"].to_s.include?("flex-wrap") && node.text.include?("Confirmar") }
      expect(group.css("button").map { |node| node.text.strip }).to eq([ "Confirmar", "Corrigir" ])
    end
  end

  it "Corrigir on the email confirmation returns the typed email" do
    norte = create_organization!(name: "ONG Norte")
    zoe = Account.create!(email: "zoe@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    as_seller do
      ActionMailer::Base.deliveries.clear
      post "/administration/email", params: { organization_id: norte.id, email: "zoe@exemplo.org" }
      post "/administration/email/continue", params: { email: " Novo@Exemplo.ORG " }
      follow_administration("/administration/#{norte.id}/edit")
      expect {
        post "/administration/correct"
      }.not_to change { [ Access.count, Account.count ] }

      follow_administration("/administration/#{norte.id}/edit")
      expect(ActionMailer::Base.deliveries).to be_empty
      expect(organization_row(norte).at_css('input[name="email"]')["value"]).to eq("novo@exemplo.org")
    end
  end

  it "confirming a new principal email creates the Account and sends the welcome" do
    norte = create_organization!(name: "ONG Norte")
    sul = create_organization!(name: "ONG Sul")
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

  it "confirming onto an existing Account sends no welcome" do
    _sul_account, _sul = plant_coordinator(email: "sul@exemplo.org", organization_name: "ONG Sul")
    norte = create_organization!(name: "ONG Norte")
    old = Account.create!(email: "coordenador@exemplo.org")
    Access.create!(account: old, organization: norte, kind: :coordinator)
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      post "/administration/email/continue", params: { email: "sul@exemplo.org" }
      expect {
        post "/administration/email/confirm", params: { organization_id: norte.id }
      }.not_to change(Account, :count)

      expect(old.reload.email).to eq("coordenador@exemplo.org")
      expect(norte.reload.principal_coordinator_account.email).to eq("sul@exemplo.org")
      expect(norte.accesses.coordinator.find_by(account: Account.find_by!(email: "sul@exemplo.org"))).to be_present
      expect(Access.find_by(account: old, organization: norte)).to be_nil
      expect(ActionMailer::Base.deliveries).to be_empty
      follow_redirect!
      expect(organization_row(norte).text).to include("sul@exemplo.org")
      expect(organization_row(norte).text).not_to include("E-mail enviado para")
    end
  end

  it "the welcome after an email move addresses the new email" do
    zoe = Account.create!(email: "zoe@exemplo.org")
    norte = create_organization!(name: "ONG Norte", principal_coordinator_account: zoe)
    ana = Account.create!(email: "ana@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    Access.create!(account: ana, organization: norte, kind: :coordinator)
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
    norte = create_organization!(name: "ONG Norte")
    sul = create_organization!(name: "ONG Sul")
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
    zoe = Account.create!(email: "zoe@exemplo.org")
    norte = create_organization!(name: "ONG Norte", principal_coordinator_account: zoe)
    ana = Account.create!(email: "ana@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    Access.create!(account: ana, organization: norte, kind: :coordinator)
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
    norte = create_organization!(name: "ONG Norte")
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
    norte = create_organization!(name: "ONG Norte")
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
    norte = create_organization!(name: "ONG Norte")
    old = Account.create!(email: "coordenador@exemplo.org")
    Access.create!(account: old, organization: norte, kind: :coordinator)
    as_seller do
      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      post "/administration/email/continue", params: { email: "novo@exemplo.org" }
      post "/administration/email/confirm", params: { organization_id: norte.id }

      expect(session[:organization_id]).to eq(previous.id)
    end
  end

  it "confirm of another email on the focused organization moves focus to another coordinator organization" do
    seller, sul = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Sul",
      google_uid: "uid-seller"
    )
    norte = create_organization!(name: "ONG Norte", principal_coordinator_account: seller)
    Access.create!(account: seller, organization: norte, kind: :coordinator)
    as_seller do
      post "/focus", params: { organization_id: norte.id }
      post "/administration/email", params: { organization_id: norte.id, email: "seller@example.com" }
      post "/administration/email/continue", params: { email: "novo@exemplo.org" }
      post "/administration/email/confirm", params: { organization_id: norte.id }

      expect(session[:organization_id]).to eq(sul.id)
      follow_redirect!
      expect(response).to have_http_status(:ok)
      header = page.at_css("header")
      expect(header.text).to include("Fechamento Mensal - ONG Sul")
      expect(header.css("nav a").map { |link| link.text.strip }).to eq([
        "Início", "Documentos", "Configuração", "Administração"
      ])
      expect(header.css("button").map { |button| button.text.strip }).to include("Sair")
    end
  end

  it "confirm of another email on the focused organization moves focus to a submitter organization" do
    seller, norte = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Norte",
      google_uid: "uid-seller"
    )
    leste = create_organization!(name: "ONG Leste")
    Access.create!(account: seller, organization: leste, kind: :submitter)
    as_seller do
      expect(session[:organization_id]).to eq(norte.id)
      post "/administration/email", params: { organization_id: norte.id, email: "seller@example.com" }
      post "/administration/email/continue", params: { email: "novo@exemplo.org" }
      post "/administration/email/confirm", params: { organization_id: norte.id }

      expect(session[:organization_id]).to eq(leste.id)
      follow_redirect!
      header = page.at_css("header")
      expect(header.text).to include("Fechamento Mensal - ONG Leste")
      expect(header.css("nav a").map { |link| link.text.strip }).to eq([
        "Início", "Documentos", "Administração"
      ])
      expect(header.text).not_to include("Configuração")
    end
  end

  it "confirm of another email on the last focused organization clears focus" do
    _seller, norte = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Norte",
      google_uid: "uid-seller"
    )
    as_seller do
      expect(session[:organization_id]).to eq(norte.id)
      post "/administration/email", params: { organization_id: norte.id, email: "seller@example.com" }
      post "/administration/email/continue", params: { email: "novo@exemplo.org" }
      post "/administration/email/confirm", params: { organization_id: norte.id }

      expect(session[:organization_id]).to be_nil
      follow_redirect!
      expect(response).to have_http_status(:ok)
      header = page.at_css("header")
      expect(header.text).to include("Fechamento Mensal")
      expect(header.text).not_to include("ONG Norte")
      expect(header.at_css("nav")).to be_nil
      expect(header.css("button").map { |button| button.text.strip }).to eq([ "Sair" ])
    end
  end

  it "email confirmation for a missing organization responds 404" do
    create_organization!(name: "ONG Norte")
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
      follow_administration("/administration/#{norte.id}/edit")
      expect(organization_row(norte).text).to include("Nenhum e-mail será enviado.")

      post "/administration/email", params: { organization_id: norte.id, email: "coordenador@exemplo.org" }
      follow_administration("/administration/#{norte.id}/edit")

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
      follow_administration("/administration/#{norte.id}/edit")
      expect(organization_row(norte).text).to include("novo@exemplo.org")

      expect {
        post "/administration/name", params: { organization_id: norte.id }
      }.not_to change(Access, :count)

      follow_administration("/administration/#{norte.id}/edit")
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

      follow_administration("/administration/new")
      expect(ActionMailer::Base.deliveries).to be_empty
      expect(page.at_css('form[action="/administration/confirm"]')).not_to be_nil
      expect(response.body).to include("ONG Sul")
      expect(page.at_css("[data-organization-id]")).to be_nil
    end
  end

  it "after invite accept the list column stays the principal email" do
    organization = Organization.register_coordinator(name: "ONG Norte", email: "coordenador@exemplo.org")
    invite = Invite.create!(organization: organization, email: "ana@exemplo.org", kind: :coordinator)
    ana = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")
    invite.accept!(ana)
    as_seller do
      get "/administration"

      expect(organization_row(organization).text).to include("coordenador@exemplo.org")
      expect(organization_row(organization).text).not_to include("ana@exemplo.org")
    end
  end

  it "removing an organization keeps Account rows including a coordinator who still accesses another organization" do
    extra, sul = plant_coordinator(email: "extra@exemplo.org", organization_name: "ONG Sul", google_uid: "uid-extra")
    principal = Account.create!(email: "coordenador@exemplo.org")
    norte = create_organization!(
      name: "ONG Norte",
      principal_coordinator_account: principal,
      accountant_presentation_name: "Ana Contábil"
    )
    Access.create!(account: principal, organization: norte, kind: :coordinator)
    Access.create!(account: extra, organization: norte, kind: :coordinator)
    submitter = Account.create!(email: "submitter@exemplo.org")
    Access.create!(account: submitter, organization: norte, kind: :submitter)
    Invite.create!(organization: norte, email: "pessoa@exemplo.org", kind: :coordinator)
    as_seller do
      delete "/administration", params: { organization_id: norte.id }

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to("/administration")
      expect(Organization.find_by(id: norte.id)).to be_nil
      expect(Access.where(organization_id: norte.id)).to be_empty
      expect(Invite.where(organization_id: norte.id)).to be_empty
      expect(Account.find(principal.id)).to eq(principal)
      expect(Account.find(submitter.id)).to eq(submitter)
      expect(Account.find(extra.id)).to eq(extra)
      expect(Access.find_by(account: extra, organization: sul)).to be_present
      follow_redirect!
      expect(response.body).not_to include("ONG Norte")
    end
  end

  it "GET /administration after removing the focused organization focuses another coordinator organization" do
    seller, norte = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Norte",
      google_uid: "uid-seller"
    )
    sul = create_organization!(name: "ONG Sul", principal_coordinator_account: seller)
    Access.create!(account: seller, organization: sul, kind: :coordinator)
    as_seller do
      post "/focus", params: { organization_id: norte.id }
      expect(session[:organization_id]).to eq(norte.id)
      delete "/administration", params: { organization_id: norte.id }
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(session[:organization_id]).to eq(sul.id)
      expect(page.at_css("header").text).to include("Fechamento Mensal - ONG Sul")
    end
  end

  it "GET /administration after removing the last focused organization clears focus" do
    account, norte = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Norte",
      google_uid: "uid-seller"
    )
    as_seller do
      expect(session[:organization_id]).to eq(norte.id)
      delete "/administration", params: { organization_id: norte.id }
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(session[:organization_id]).to be_nil
      header = page.at_css("header")
      expect(header.text).to include("Fechamento Mensal")
      expect(header.text).not_to include("ONG Norte")
      expect(header.at_css("nav")).to be_nil
      expect(account.reload).to eq(account)
    end
  end

  it "removing another organization leaves the focused organization" do
    _account, sul = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Sul",
      google_uid: "uid-seller"
    )
    norte = create_organization!(name: "ONG Norte")
    other = Account.create!(email: "coordenador@exemplo.org")
    Access.create!(account: other, organization: norte, kind: :coordinator)
    as_seller do
      expect(session[:organization_id]).to eq(sul.id)
      delete "/administration", params: { organization_id: norte.id }
      follow_redirect!

      expect(session[:organization_id]).to eq(sul.id)
      expect(page.at_css("header").text).to include("Fechamento Mensal - ONG Sul")
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
    ExtraExceptionKind.create_for(organization: norte, name: "Doação", justification: "Isento de documento de suporte.")
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
    kept = create_organization!(name: "ONG Sul")
    missing_id = Organization.maximum(:id).to_i + 1
    as_seller do
      delete "/administration", params: { organization_id: missing_id }

      expect(response).to have_http_status(:not_found)
      expect(Organization.find(kept.id)).to eq(kept)
    end
  end

  it "GET /administration after removing the result organization shows the empty list" do
    as_seller do
      post "/administration", params: { name: "ONG Norte", email: "coordenador@exemplo.org" }
      post "/administration/confirm"
      norte = Organization.find_by!(name: "ONG Norte")
      delete "/administration", params: { organization_id: norte.id }
      get "/administration"

      expect(response).to have_http_status(:ok)
      expect(page.css("a").find { |link| link.text.strip == "Adicionar organização" }).to be_present
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
