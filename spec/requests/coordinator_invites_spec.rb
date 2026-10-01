require "rails_helper"

RSpec.describe "Coordinator invites", type: :request do
  before { ActionMailer::Base.register_interceptor(CoordinatorInviteDeliveryFail) }
  after do
    CoordinatorInviteDeliveryFail.raise_now = false
    ActionMailer::Base.unregister_interceptor(CoordinatorInviteDeliveryFail)
  end
  it "POST /coordinator_invites persists a coordinator Invite and redirects" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    expect do
      post "/coordinator_invites", params: { email: "guest@example.com" }
    end.to change(Invite, :count).by(1)

    invite = Invite.last
    expect(invite.email).to eq("guest@example.com")
    expect(invite.kind).to eq("coordinator")
    expect(invite.organization).to eq(organization)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
  end

  it "POST /coordinator_invites delivers the coordinator invite" do
    account, organization = plant_coordinator(organization_name: "ONG Norte")
    sign_in_as(account, organization: organization)
    ActionMailer::Base.deliveries.clear

    with_env("MAIL_FROM" => "venda@example.com") do
      post "/coordinator_invites", params: { email: " Pessoa@Exemplo.ORG " }
    end

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    expect(Invite.find_by!(email: "pessoa@exemplo.org", organization: organization).kind).to eq("coordinator")
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    message = ActionMailer::Base.deliveries.last
    expect(message.mime_type).to eq("text/plain")
    expect(message.from).to eq([ "venda@example.com" ])
    expect(message.to).to eq([ "pessoa@exemplo.org" ])
    expect(message.subject).to eq("Fechamento Mensal - Convite para ONG Norte")
    expect(message.body.decoded).to eq(
      "Você foi convidado a fechar o mês da organização ONG Norte. Entre com o Google usando pessoa@exemplo.org, pelo botão Entrar com Google."
    )
    follow_redirect!
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
    expect(page_doc(response.body).css("[data-notice='error']")).to be_empty
    expect(response.body).not_to include("E-mail enviado")
    item = page_doc(response.body).css("li").find { |node| node.text.include?("pessoa@exemplo.org") }
    expect(item.inner_html.index("Reenviar e-mail")).to be < item.inner_html.index("Cancelar")
    resend = item.css("button").find { |button| button.text.strip == "Reenviar e-mail" }
    expect(resend["class"]).to include("text-caixa")
    expect(resend["class"]).to include("underline")
    expect(resend["class"]).to include("underline-offset-2")
    cancel = item.css("button").find { |button| button.text.strip == "Cancelar" }
    expect(cancel["class"]).to include("text-margem")
    expect(cancel["class"]).to include("underline")
    expect(cancel["class"]).to include("underline-offset-2")
  end

  it "rejected invite emails return 422" do
    account, organization = plant_coordinator(email: "coord@example.com")
    standing = Account.create!(email: "standing@example.com", google_uid: "uid-standing")
    Access.create!(account: standing, organization: organization, kind: :coordinator)
    Invite.create!(organization: organization, email: "pending@example.com", kind: :coordinator)
    sign_in_as(account, organization: organization)

    [
      "standing@example.com",
      "pending@example.com",
      "nao-e-email"
    ].each do |email|
      ActionMailer::Base.deliveries.clear
      expect do
        post "/coordinator_invites", params: { email: email }
      end.not_to change(Invite, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(ActionMailer::Base.deliveries).to be_empty
      expect(toast_node(response.body)).to be_nil
    end
  end

  it "unauthenticated POST /coordinator_invites responds 302 to /login" do
    expect do
      post "/coordinator_invites", params: { email: "guest@example.com" }
    end.not_to change { [ Invite.count, ActionMailer::Base.deliveries.size ] }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "DELETE /coordinator_invites/:id redirects" do
    account, organization = plant_coordinator
    invite = Invite.create!(organization: organization, email: "guest@example.com", kind: :coordinator)
    sign_in_as(account, organization: organization)

    delete "/coordinator_invites/#{invite.id}"

    expect(Invite.find_by(id: invite.id)).to be_nil
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
  end

  it "DELETE /coordinator_invites/:id of another organization returns 404" do
    account, organization = plant_coordinator(email: "a@example.com", organization_name: "A")
    other = create_organization!(name: "B")
    invite = Invite.create!(organization: other, email: "guest@example.com", kind: :coordinator)
    sign_in_as(account, organization: organization)

    delete "/coordinator_invites/#{invite.id}"

    expect(response).to have_http_status(:not_found)
    expect(Invite.find(invite.id)).to eq(invite)
  end

  def raise_invite_delivery
    CoordinatorInviteDeliveryFail.raise_now = true
  end

  def allow_invite_delivery
    CoordinatorInviteDeliveryFail.raise_now = false
  end

  it "POST /coordinator_invites keeps the Invite when deliver_now raises" do
    account, organization = plant_coordinator(organization_name: "ONG Norte")
    sign_in_as(account, organization: organization)
    raise_invite_delivery
    post "/coordinator_invites", params: { email: "pessoa@exemplo.org" }

    expect(Invite.find_by!(email: "pessoa@exemplo.org", organization: organization)).to be_present
    expect(session[:invite_mail_failed]).not_to eq(true)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    follow_redirect!
    expect(response).to have_http_status(:ok)
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include("O convite foi gravado, mas o e-mail não saiu.")
    notice_with_mail = page_doc(response.body).css("[data-notice='error']").find { |node|
      node.text.include?("O convite foi gravado, mas o e-mail não saiu.")
    }
    expect(notice_with_mail).to be_nil
  end

  it "second GET after invite mail failure has no toast" do
    account, organization = plant_coordinator(organization_name: "ONG Norte")
    sign_in_as(account, organization: organization)
    raise_invite_delivery
    post "/coordinator_invites", params: { email: "pessoa@exemplo.org" }
    follow_redirect!
    expect(toast_node(response.body)["data-toast-kind"]).to eq("error")

    get "/"

    expect(toast_node(response.body)).to be_nil
    expect(response.body).not_to include("O convite foi gravado, mas o e-mail não saiu.")
  end

  it "resend on another Invite delivers Pronto toast" do
    account, organization = plant_coordinator(organization_name: "ONG Norte")
    other = Invite.create!(organization: organization, email: "outro@exemplo.org", kind: :coordinator)
    sign_in_as(account, organization: organization)
    raise_invite_delivery
    post "/coordinator_invites", params: { email: "pessoa@exemplo.org" }
    allow_invite_delivery
    ActionMailer::Base.deliveries.clear
    with_env("MAIL_FROM" => "venda@example.com") do
      post "/coordinator_invites/#{other.id}/mail"
    end

    expect(Invite.where(id: [ other.id, Invite.find_by!(email: "pessoa@exemplo.org").id ]).count).to eq(2)
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(ActionMailer::Base.deliveries.last.to).to eq([ "outro@exemplo.org" ])
    follow_redirect!
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
    expect(response.body).not_to include("O convite foi gravado, mas o e-mail não saiu.")
    expect(response.body).not_to include("E-mail enviado")
  end

  it "invite resend keeps the Invite when deliver_now raises" do
    account, organization = plant_coordinator
    invite = Invite.create!(organization: organization, email: "pessoa@exemplo.org", kind: :coordinator)
    sign_in_as(account, organization: organization)
    raise_invite_delivery
    post "/coordinator_invites/#{invite.id}/mail"

    expect(Invite.find(invite.id)).to eq(invite)
    follow_redirect!
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include("O convite foi gravado, mas o e-mail não saiu.")
    notice_with_mail = page_doc(response.body).css("[data-notice='error']").find { |node|
      node.text.include?("O convite foi gravado, mas o e-mail não saiu.")
    }
    expect(notice_with_mail).to be_nil
  end

  it "Cancelar shows Pronto toast and does not keep the mail failure" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    raise_invite_delivery
    post "/coordinator_invites", params: { email: "pessoa@exemplo.org" }
    invite = Invite.find_by!(email: "pessoa@exemplo.org")
    ActionMailer::Base.deliveries.clear
    delete "/coordinator_invites/#{invite.id}"

    expect(Invite.find_by(id: invite.id)).to be_nil
    expect(ActionMailer::Base.deliveries).to be_empty
    follow_redirect!
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
    expect(response.body).not_to include("O convite foi gravado, mas o e-mail não saiu.")
  end

  it "Cancelar without a failure notice delivers nothing" do
    account, organization = plant_coordinator
    invite = Invite.create!(organization: organization, email: "pessoa@exemplo.org", kind: :coordinator)
    sign_in_as(account, organization: organization)
    ActionMailer::Base.deliveries.clear
    delete "/coordinator_invites/#{invite.id}"

    expect(Invite.find_by(id: invite.id)).to be_nil
    expect(ActionMailer::Base.deliveries).to be_empty
    follow_redirect!
    expect(response.body).not_to include("O convite foi gravado, mas o e-mail não saiu.")
  end

  it "resend of another organization Invite returns 404" do
    account, organization = plant_coordinator(email: "a@example.com", organization_name: "A")
    other = create_organization!(name: "B")
    invite = Invite.create!(organization: other, email: "guest@example.com", kind: :coordinator)
    sign_in_as(account, organization: organization)
    ActionMailer::Base.deliveries.clear
    post "/coordinator_invites/#{invite.id}/mail"

    expect(response).to have_http_status(:not_found)
    expect(Invite.find(invite.id)).to eq(invite)
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "unauthenticated invite resend responds 302 to /login" do
    organization = create_organization!(name: "ONG Norte")
    invite = Invite.create!(organization: organization, email: "pessoa@exemplo.org", kind: :coordinator)
    expect do
      post "/coordinator_invites/#{invite.id}/mail"
    end.not_to change { [ Invite.count, ActionMailer::Base.deliveries.size ] }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "a later invite send clears the failure notice" do
    account, organization = plant_coordinator(organization_name: "ONG Norte")
    sign_in_as(account, organization: organization)
    raise_invite_delivery
    post "/coordinator_invites", params: { email: "pessoa@exemplo.org" }
    allow_invite_delivery
    with_env("MAIL_FROM" => "venda@example.com") do
      post "/coordinator_invites", params: { email: "nova@exemplo.org" }
    end

    expect(Invite.where(organization: organization, email: [ "pessoa@exemplo.org", "nova@exemplo.org" ]).count).to eq(2)
    follow_redirect!
    expect(response.body).not_to include("O convite foi gravado, mas o e-mail não saiu.")
  end
end
