require "rails_helper"

RSpec.describe "Submitter invites", type: :request do
  it "POST /submitter_invites persists a submitter Invite and redirects" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    expect do
      post "/submitter_invites", params: { email: "guest@example.com" }
    end.to change(Invite, :count).by(1)

    invite = Invite.last
    expect(invite.email).to eq("guest@example.com")
    expect(invite.kind).to eq("submitter")
    expect(invite.organization).to eq(organization)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    follow_redirect!
    expect(response.body).to include("guest@example.com")
  end

  it "POST /submitter_invites delivers the submitter invite" do
    account, organization = plant_coordinator(organization_name: "ONG Norte")
    sign_in_as(account, organization: organization)
    ActionMailer::Base.deliveries.clear

    with_env("MAIL_FROM" => "venda@example.com") do
      post "/submitter_invites", params: { email: "docs@exemplo.org" }
    end

    expect(Invite.find_by!(email: "docs@exemplo.org", organization: organization).kind).to eq("submitter")
    message = ActionMailer::Base.deliveries.last
    expect(message.subject).to eq("Fechamento Mensal - Convite para ONG Norte")
    expect(message.body.decoded).to eq(
      "Você foi convidado a enviar documentos da organização ONG Norte. Entre com o Google usando docs@exemplo.org, pelo botão Entrar com Google."
    )
    follow_redirect!
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
  end

  it "rejected submitter invite emails return 422" do
    account, organization = plant_coordinator(email: "coord@example.com")
    standing_coord = Account.create!(email: "standing-coord@example.com", google_uid: "uid-standing-coord")
    Access.create!(account: standing_coord, organization: organization, kind: :coordinator)
    standing_sub = Account.create!(email: "standing-sub@example.com", google_uid: "uid-standing-sub")
    Access.create!(account: standing_sub, organization: organization, kind: :submitter)
    Invite.create!(organization: organization, email: "pending@example.com", kind: :submitter)
    sign_in_as(account, organization: organization)

    [
      "standing-coord@example.com",
      "standing-sub@example.com",
      "pending@example.com",
      "nao-e-email"
    ].each do |email|
      ActionMailer::Base.deliveries.clear
      expect do
        post "/submitter_invites", params: { email: email }
      end.not_to change(Invite, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  it "unauthenticated POST /submitter_invites responds 302 to /login" do
    expect do
      post "/submitter_invites", params: { email: "guest@example.com" }
    end.not_to change { [ Invite.count, ActionMailer::Base.deliveries.size ] }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "DELETE /submitter_invites/:id redirects" do
    account, organization = plant_coordinator
    invite = Invite.create!(organization: organization, email: "guest@example.com", kind: :submitter)
    sign_in_as(account, organization: organization)

    delete "/submitter_invites/#{invite.id}"

    expect(Invite.find_by(id: invite.id)).to be_nil
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
  end

  it "submitter POST invites persist no Invite and respond 404" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    [
      "/coordinator_invites",
      "/submitter_invites"
    ].each do |path|
      expect do
        post path, params: { email: "guest@example.com" }
      end.not_to change(Invite, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
