require "rails_helper"

RSpec.describe "Administration access", type: :request do
  include AdministrationHelpers

  it "GET /administration lists the first coordinator, status, and Editar" do
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

      row = organization_row(norte)
      expect(row.css("a").find { |link| link.text.strip == "Editar" }["href"]).to eq("/administration/#{norte.id}/edit")
      expect(row.text).to include("ONG Norte")
      expect(row.text).to include("ana@exemplo.org")
      expect(row.text).to include("Pendente")
      expect(row.text).not_to include("zoe@exemplo.org")
      expect(row.text).not_to include("Corrigir nome")
      expect(row.text).not_to include("Remover")
      expect(response.body).not_to include("submitter@exemplo.org")
      expect(organization_row(sul).text).to include("Ativa")
    end
  end

  it "GET /administration/:id/edit shows Corrigir on each coordinator email and Remover" do
    plant_coordinator(email: "sul@exemplo.org", organization_name: "ONG Sul", google_uid: "uid-sul")
    norte = Organization.create!(name: "ONG Norte")
    zoe = Account.create!(email: "zoe@exemplo.org")
    ana = Account.create!(email: "ana@exemplo.org")
    submitter = Account.create!(email: "submitter@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    Access.create!(account: ana, organization: norte, kind: :coordinator)
    Access.create!(account: submitter, organization: norte, kind: :submitter)

    as_seller do
      get "/administration/#{norte.id}/edit"

      column = administration_column
      row = organization_row(norte)
      expect(column.css("[data-organization-id='#{norte.id}']").size).to eq(1)
      expect(page.at_css("h1").text.strip).to eq("Editar organização")
      expect(row.css("p, button").map { |node| node.text.strip }).to eq([
        "ONG Norte",
        "Corrigir nome",
        "ana@exemplo.org",
        "Corrigir",
        "zoe@exemplo.org",
        "Corrigir",
        "Remover"
      ])
      buttons = row.css("button").map { |button| button.text.strip }
      expect(buttons).to include("Corrigir nome")
      expect(buttons.count("Corrigir")).to eq(2)
      expect(buttons).to include("Remover")
      corrects = row.css("button").select { |button| button.text.strip == "Corrigir" }
      expect(corrects.size).to eq(2)
      corrects.each do |button|
        expect(button["class"]).to include("text-caixa")
        expect(button["class"]).to include("underline")
        expect(button["class"]).to include("underline-offset-2")
      end
      ana_correct = corrects.first
      expect(ana_correct.ancestors("form").first["action"]).to eq("/administration/email")
      remover = row.css("button").find { |button| button.text.strip == "Remover" }
      expect(remover["class"]).to include("text-margem")
      expect(remover["class"]).to include("underline")
      expect(remover["class"]).to include("underline-offset-2")
      form = remover.ancestors("form").first
      expect(form["data-turbo-confirm"]).to eq("Remover a organização ONG Norte?")
      expect(form["action"]).to eq("/administration")
      expect(form.at_css('input[name="_method"]')["value"]).to eq("delete")
      expect(response.body).not_to include("submitter@exemplo.org")
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

      follow_administration("/administration/#{norte.id}/edit")
      row = organization_row(norte)
      expect(row.text).to include("ONG Norte")
      field = row.at_css('input[type="email"]')
      expect(field["value"]).to eq("zoe@exemplo.org")
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

      follow_administration("/administration/#{norte.id}/edit")
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

      follow_administration("/administration/#{norte.id}/edit")
      expect(response).to have_http_status(:ok)
      row = organization_row(norte)
      html = row.inner_html
      expect(html.index("Nome da organização")).to be < html.index("ONG Norte")
      expect(html.index("ONG Norte")).to be < html.index("E-mail do coordenador")
      expect(html.index("E-mail do coordenador")).to be < html.index("novo@exemplo.org")
      name_label = row.css("p").find { |node| node.text.strip == "Nome da organização" }
      expect(name_label.next_element.text.strip).to eq("ONG Norte")
      email_label = row.css("p").find { |node| node.text.strip == "E-mail do coordenador" }
      expect(email_label.next_element.text.strip).to eq("novo@exemplo.org")
      expect(row.text).not_to include("ana@exemplo.org")
      group = row.css("div").find { |node| node["class"].to_s.include?("flex-wrap") && node.text.include?("Confirmar") }
      expect(group.css("button").map { |node| node.text.strip }).to eq([ "Confirmar", "Corrigir" ])
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
      follow_administration("/administration/#{norte.id}/edit")
      expect {
        post "/administration/correct"
      }.not_to change { [ Access.count, Account.count ] }

      follow_administration("/administration/#{norte.id}/edit")
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
