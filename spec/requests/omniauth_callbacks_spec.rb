require "rails_helper"

RSpec.describe "OmniAuth callbacks", type: :request do
  it "verified coordinator callback redirects to organization home" do
    _account, organization = plant_coordinator(
      email: "coord@example.com",
      organization_name: "ONG Norte",
      google_uid: "uid-coord"
    )

    google_callback(email: "coord@example.com", uid: "uid-coord")

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    expect(session[:account_id]).to eq(Account.find_by!(email: "coord@example.com").id)
    expect(session[:organization_id]).to eq(organization.id)

    follow_redirect!
    expect(response.body).to include("ONG Norte")
  end

  it "second callback reuses Account" do
    account, _organization = plant_coordinator(email: "coord@example.com", google_uid: "uid-coord")

    google_callback(email: "coord@example.com", uid: "uid-coord")
    google_callback(email: "coord@example.com", uid: "uid-coord")

    expect(Account.where(email: "coord@example.com").count).to eq(1)
    expect(session[:account_id]).to eq(account.id)
  end

  it "unverified email persists no Account and redirects to /login" do
    expect do
      google_callback(email: "unverified@example.com", verified: false, uid: "uid-unverified")
    end.not_to change(Account, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(session[:account_id]).to be_nil
  end

  it "OmniAuth failure redirects to /login with no session" do
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

    get "/auth/google_oauth2/callback"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(session[:account_id]).to be_nil
  end

  it "POST /auth/google_oauth2 responds 302" do
    ActionController::Base.allow_forgery_protection = true
    get "/login"
    token = Nokogiri::HTML(response.body).at_css('input[name="authenticity_token"]')&.[]("value")
    expect(token).to be_present

    post "/auth/google_oauth2", params: { authenticity_token: token }

    expect(response).to have_http_status(:found)
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  it "uninvited callback persists no Account and redirects to /denied" do
    expect do
      google_callback(email: "stranger@example.com", uid: "uid-stranger")
    end.not_to change(Account, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/denied")
    expect(session[:account_id]).to be_nil
  end

  it "second uninvited callback still persists no Account" do
    google_callback(email: "stranger@example.com", uid: "uid-stranger")
    expect do
      google_callback(email: "stranger@example.com", uid: "uid-stranger")
    end.not_to change(Account, :count)

    expect(Account.find_by(email: "stranger@example.com")).to be_nil
  end

  it "callback matching Invite grants Access and deletes Invite" do
    _planter, organization = plant_coordinator(email: "coord@example.com")
    Invite.create!(organization: organization, email: "guest@example.com", kind: :coordinator)

    expect do
      google_callback(email: "guest@example.com", uid: "uid-guest")
    end.to change(Account, :count).by(1)
      .and change { organization.accesses.coordinator.count }.by(1)

    guest = Account.find_by!(email: "guest@example.com")
    expect(organization.accesses.find_by(account: guest).kind).to eq("coordinator")
    expect(Invite.find_by(email: "guest@example.com")).to be_nil
    expect(session[:account_id]).to eq(guest.id)
    expect(session[:organization_id]).to eq(organization.id)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
  end

  it "callback with zero Access redirects to /denied and keeps Account" do
    account = Account.create!(email: "former@example.com", google_uid: "uid-former")

    expect do
      google_callback(email: "former@example.com", uid: "uid-former")
    end.not_to change(Account, :count)

    expect(Account.find_by!(email: "former@example.com")).to eq(account)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/denied")
    expect(session[:organization_id]).to be_nil
  end
end
