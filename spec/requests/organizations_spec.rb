require "rails_helper"

RSpec.describe "Organization home", type: :request do
  it "organization home lists standing and pending coordinator emails" do
    account, organization = plant_coordinator(email: "coord@example.com")
    Invite.create!(organization: organization, email: "guest@example.com", kind: :coordinator)
    sign_in_as(account, organization: organization)

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("coord@example.com")
    expect(response.body).to include("guest@example.com")
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
    second = Organization.create!(name: "ONG Sul")
    Access.create!(account: account, organization: second, kind: :coordinator)
    sign_in_as(account, organization: first)

    get "/"

    expect(response.body).to include("ONG Norte")
    expect(response.body).to include("ONG Sul")
  end

  it "focused home does not list another organization Access or Invite" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "A")
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    other = Account.create!(email: "only-b@example.com", google_uid: "uid-only-b")
    Access.create!(account: other, organization: org_b, kind: :coordinator)
    Invite.create!(organization: org_b, email: "invite-b@example.com", kind: :coordinator)
    sign_in_as(account, organization: org_a)

    get "/"

    expect(response.body).not_to include("only-b@example.com")
    expect(response.body).not_to include("invite-b@example.com")
  end

  it "organization home links Configuracao to /setup" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Configuração")
    expect(response.body).to include('href="/setup"')
  end
end
