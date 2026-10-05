require "rails_helper"

RSpec.describe "Development sessions", type: :request do
  it "GET /login in test does not offer Ambiente local" do
    get "/login"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Entrar com Google")
    expect(response.body).not_to include("Ambiente local")
    expect(response.body).not_to include("/dev/session")
  end

  it "POST /dev/session as coordinator sets session and redirects to /" do
    account, organization = plant_coordinator(email: "coord@example.com")

    expect do
      post "/dev/session", params: { email: "coord@example.com" }
    end.not_to change(Account, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    expect(session[:account_id]).to eq(account.id)
    expect(session[:organization_id]).to eq(organization.id)
  end

  it "POST /dev/session as submitter sets session and redirects to /" do
    account, organization = plant_submitter(email: "docs@example.com")

    post "/dev/session", params: { email: "Docs@Example.com" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    expect(session[:account_id]).to eq(account.id)
    expect(session[:organization_id]).to eq(organization.id)
  end

  it "POST /dev/session as allowlisted Account with zero Access redirects to /administration" do
    account = Account.create!(email: "seller@example.com")

    with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
      post "/dev/session", params: { email: "seller@example.com" }
    end

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/administration")
    expect(session[:account_id]).to eq(account.id)
    expect(session[:organization_id]).to be_nil
  end

  it "POST /dev/session for unknown email persists no Account and redirects to /denied" do
    expect do
      post "/dev/session", params: { email: "stranger@example.com" }
    end.not_to change(Account, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/denied")
    expect(session[:account_id]).to be_nil
  end

  it "POST /dev/session for Account with zero Access that is not allowlisted redirects to /denied" do
    Account.create!(email: "stranded@example.com")

    post "/dev/session", params: { email: "stranded@example.com" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/denied")
    expect(session[:account_id]).to be_nil
  end
end
