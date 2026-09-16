require "rails_helper"

RSpec.describe "Sessions", type: :request do
  it "unauthenticated GET / responds 302 to /login" do
    get "/"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "GET /login responds 200 with Entrar com Google" do
    get "/login"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Entrar com Google")
  end

  it "DELETE /session clears session and redirects to /login" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    delete "/session"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(session[:account_id]).to be_nil
    expect(session[:organization_id]).to be_nil
  end

  it "login and organization home use locale pt-BR" do
    get "/login"
    expect(response.body).to include('lang="pt-BR"')

    account, organization = plant_coordinator(organization_name: "ONG Sul")
    sign_in_as(account, organization: organization)
    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('lang="pt-BR"')
  end

  it "no public registration route persists an Account" do
    expect do
      post "/signup", params: { email: "public@example.com", password: "secret" }
    end.not_to change(Account, :count)

    expect(response).to have_http_status(:not_found)
    expect(Account.find_by(email: "public@example.com")).to be_nil
  end
end
