require "rails_helper"

RSpec.describe "OmniAuth callbacks", type: :request do
  it "verified coordinator callback redirects to organization home" do
    _account, organization = plant_coordinator(
      email: "coordenador@exemplo.org",
      organization_name: "ONG Norte",
      google_uid: "uid-coord"
    )

    google_callback(email: "coordenador@exemplo.org", uid: "uid-coord")

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    expect(session[:account_id]).to eq(Account.find_by!(email: "coordenador@exemplo.org").id)
    expect(session[:organization_id]).to eq(organization.id)

    follow_redirect!
    expect(response.body).to include("ONG Norte")
    expect(response.body).not_to include("Você não foi convidado a usar este sistema.")
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

  it "callback matching submitter Invite grants submitter Access" do
    _planter, organization = plant_coordinator(email: "coord@example.com", organization_name: "ONG Norte")
    Invite.create!(organization: organization, email: "guest@example.com", kind: :submitter)

    expect do
      google_callback(email: "guest@example.com", uid: "uid-guest")
    end.to change(Account, :count).by(1)
      .and change { organization.accesses.submitter.count }.by(1)

    guest = Account.find_by!(email: "guest@example.com")
    expect(organization.accesses.find_by(account: guest).kind).to eq("submitter")
    expect(organization.accesses.coordinator.where(account: guest)).to be_empty
    expect(Invite.find_by(email: "guest@example.com")).to be_nil
    expect(session[:account_id]).to eq(guest.id)
    expect(session[:organization_id]).to eq(organization.id)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("ONG Norte")
  end

  it "second submitter callback reuses Account and Access" do
    account, organization = plant_submitter(email: "sub@example.com")

    google_callback(email: "sub@example.com", uid: account.google_uid)
    google_callback(email: "sub@example.com", uid: account.google_uid)

    expect(Account.where(email: "sub@example.com").count).to eq(1)
    expect(organization.accesses.where(account: account).count).to eq(1)
    expect(session[:account_id]).to eq(account.id)
  end

  it "callback accepts submitter Invite on B for coordinator of A" do
    account, _org_a = plant_coordinator(email: "mixed@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Invite.create!(organization: org_b, email: "mixed@example.com", kind: :submitter)

    expect do
      google_callback(email: "mixed@example.com", uid: account.google_uid)
    end.not_to change(Account, :count)

    expect(org_b.accesses.find_by!(account: account).kind).to eq("submitter")
    expect(Invite.find_by(email: "mixed@example.com")).to be_nil
    expect(session[:account_id]).to eq(account.id)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
  end

  it "submitter callback with standing Access and no Invite signs in" do
    account, organization = plant_submitter(email: "sub@example.com", organization_name: "ONG Sul")

    google_callback(email: "sub@example.com", uid: account.google_uid)

    expect(session[:account_id]).to eq(account.id)
    expect(session[:organization_id]).to eq(organization.id)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
  end

  it "revoked submitter callback keeps Account and redirects to /denied" do
    account, organization = plant_submitter(email: "former@example.com")
    organization.accesses.submitter.find_by!(account: account).destroy!

    expect do
      google_callback(email: "former@example.com", uid: account.google_uid)
    end.not_to change(Account, :count)

    expect(Account.find_by!(email: "former@example.com")).to eq(account)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/denied")
    expect(session[:organization_id]).to be_nil
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

  it "allowlisted callback with no Account redirects to /administration" do
    with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
      google_callback(email: "seller@example.com", uid: "uid-seller")
    end

    account = Account.find_by!(email: "seller@example.com")
    expect(account.google_uid).to eq("uid-seller")
    expect(account.accesses).to be_empty
    expect(Organization.count).to eq(0)
    expect(Access.count).to eq(0)
    expect(session[:account_id]).to eq(account.id)
    expect(session[:organization_id]).to be_nil
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/administration")
  end

  it "allowlisted coordinator callback keeps the organization and redirects home" do
    _account, organization = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Norte",
      google_uid: "uid-seller"
    )

    expect {
      with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
        google_callback(email: "seller@example.com", uid: "uid-seller")
      end
    }.not_to change(Account, :count)

    expect(session[:organization_id]).to eq(organization.id)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
  end

  it "allowlisted callback with a pending Invite accepts the Invite and redirects home" do
    organization = create_organization!(name: "ONG Norte")
    Invite.create!(organization: organization, email: "seller@example.com", kind: :coordinator)

    with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
      google_callback(email: "seller@example.com", uid: "uid-seller")
    end

    account = Account.find_by!(email: "seller@example.com")
    expect(Account.where(email: "seller@example.com").count).to eq(1)
    expect(organization.accesses.find_by!(account: account).kind).to eq("coordinator")
    expect(Invite.find_by(email: "seller@example.com")).to be_nil
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
  end

  it "uninvited callback persists no Account and the denied page names the refusal" do
    expect {
      with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
        google_callback(email: "other@example.com", uid: "uid-other")
      end
    }.not_to change(Account, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/denied")
    follow_redirect!
    expect(response.body).to include("Você não foi convidado a usar este sistema.")
    expect(Account.find_by(email: "other@example.com")).to be_nil
  end

  it "unverified allowlisted callback persists no Account and redirects to /login" do
    expect {
      with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
        google_callback(email: "seller@example.com", verified: false, uid: "uid-seller")
      end
    }.not_to change(Account, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(Account.find_by(email: "seller@example.com")).to be_nil
  end

  it "blank administrator email persists no Account and redirects to /denied" do
    [ nil, "" ].each do |value|
      expect {
        with_env("ADMINISTRATOR_EMAIL" => value) do
          google_callback(email: "stranger@example.com", uid: "uid-blank")
        end
      }.not_to change(Account, :count)

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to("/denied")
      expect(Account.find_by(email: "stranger@example.com")).to be_nil
    end
  end

  it "mixed-case administrator email is the same door" do
    with_env("ADMINISTRATOR_EMAIL" => "Seller@Example.com") do
      google_callback(email: "seller@example.com", uid: "uid-seller")
    end

    account = Account.find_by!(email: "seller@example.com")
    expect(account.google_uid).to eq("uid-seller")
    expect(account.accesses).to be_empty
    expect(Organization.count).to eq(0)
    expect(session[:account_id]).to eq(account.id)
    expect(session[:organization_id]).to be_nil
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/administration")
  end

  it "allowlisted Account with zero Access signs in without a second Account" do
    account = Account.create!(email: "seller@example.com")

    expect {
      with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
        google_callback(email: "seller@example.com", uid: "uid-seller")
      end
    }.not_to change(Account, :count)

    expect(account.reload.google_uid).to eq("uid-seller")
    expect(Organization.count).to eq(0)
    expect(account.accesses).to be_empty
    expect(session[:account_id]).to eq(account.id)
    expect(session[:organization_id]).to be_nil
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/administration")
  end
end
