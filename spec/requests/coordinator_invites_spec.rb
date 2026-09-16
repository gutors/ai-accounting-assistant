require "rails_helper"

RSpec.describe "Coordinator invites", type: :request do
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

  it "rejected invite emails return 422" do
    account, organization = plant_coordinator(email: "coord@example.com")
    standing = Account.create!(email: "standing@example.com", google_uid: "uid-standing")
    Access.create!(account: standing, organization: organization, kind: :coordinator)
    Invite.create!(organization: organization, email: "pending@example.com", kind: :coordinator)
    sign_in_as(account, organization: organization)

    [
      "standing@example.com",
      "pending@example.com",
      "not-an-email"
    ].each do |email|
      expect do
        post "/coordinator_invites", params: { email: email }
      end.not_to change(Invite, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  it "unauthenticated POST /coordinator_invites responds 302 to /login" do
    expect do
      post "/coordinator_invites", params: { email: "guest@example.com" }
    end.not_to change(Invite, :count)

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
    other = Organization.create!(name: "B")
    invite = Invite.create!(organization: other, email: "guest@example.com", kind: :coordinator)
    sign_in_as(account, organization: organization)

    delete "/coordinator_invites/#{invite.id}"

    expect(response).to have_http_status(:not_found)
    expect(Invite.find(invite.id)).to eq(invite)
  end
end
