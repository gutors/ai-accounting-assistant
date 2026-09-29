require "rails_helper"

RSpec.describe "Bank accounts", type: :request do
  it "POST /bank_accounts persists active Banco do Brasil account and redirects" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    post "/bank_accounts", params: { name: "Conta Principal", compe: "001" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    bank_account = organization.bank_accounts.last
    expect(bank_account).to be_active
    expect(bank_account.bank.presentation_name).to eq("Banco do Brasil")
    expect(bank_account.slug).to eq(ActiveSupport::Inflector.parameterize("Conta Principal"))

    get "/setup"
    expect(response.body).to include("Conta Principal")
    expect(response.body).to include("extrato-#{bank_account.slug}")
  end

  it "POST /bank_accounts BB agencia 1234 shows extrato-bb-agencia-1234" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    post "/bank_accounts", params: { name: "BB agência 1234", compe: "001" }

    expect(organization.bank_accounts.last.slug).to eq("bb-agencia-1234")
    get "/setup"
    expect(response.body).to include("extrato-bb-agencia-1234")
  end

  it "POST /bank_accounts allows two accounts at the same bank" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    post "/bank_accounts", params: { name: "Conta 1", compe: "001" }
    post "/bank_accounts", params: { name: "Conta 2", compe: "001" }

    expect(organization.bank_accounts.count).to eq(2)
  end

  it "POST /bank_accounts persists trimmed coordinates" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    post "/bank_accounts", params: { name: "Principal", compe: "001", coordinates: "  ag 1234  " }

    expect(organization.bank_accounts.last.coordinates).to eq("ag 1234")
    get "/setup"
    expect(response.body).to include("ag 1234")
  end

  it "PATCH /bank_accounts/:id updates name and slug" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: "Antiga", compe: "001")

    patch "/bank_accounts/#{bank_account.id}", params: { name: "Nova Conta" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    bank_account.reload
    expect(bank_account.name).to eq("Nova Conta")
    expect(bank_account.slug).to eq("nova-conta")
  end

  it "POST and PATCH colliding slug return 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Café", compe: "001")

    post "/bank_accounts", params: { name: "Cafe", compe: "033" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.bank_accounts.count).to eq(1)

    other = BankAccount.create_for(organization: organization, name: "Outra", compe: "033")
    patch "/bank_accounts/#{other.id}", params: { name: "Cafe" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(other.reload.name).to eq("Outra")
  end

  it "POST /bank_accounts empty slug returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    post "/bank_accounts", params: { name: "---", compe: "001" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.bank_accounts.count).to eq(0)
  end

  it "POST /bank_accounts unknown COMPE returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    post "/bank_accounts", params: { name: "Principal", compe: "999" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.bank_accounts.count).to eq(0)
  end

  it "unauthenticated POST /bank_accounts responds 302 to /login" do
    expect do
      post "/bank_accounts", params: { name: "Principal", compe: "001" }
    end.not_to change(BankAccount, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "PATCH /bank_accounts/:id to inactive keeps row and shows Inativa" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: "Principal", compe: "001")

    patch "/bank_accounts/#{bank_account.id}", params: { active: false }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    expect(BankAccount.find(bank_account.id)).not_to be_active

    get "/setup"
    expect(response.body).to include("Principal")
    expect(response.body).to include("Inativa")
  end

  it "PATCH /bank_accounts/:id to active omits Inativa" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: "Principal", compe: "001")
    bank_account.apply_from(active: false)

    patch "/bank_accounts/#{bank_account.id}", params: { active: true }

    get "/setup"
    expect(response.body).to include("Principal")
    expect(response.body).not_to include("Inativa")
  end

  it "DELETE /bank_accounts/:id returns 404 and keeps the row" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: "Principal", compe: "001")

    delete "/bank_accounts/#{bank_account.id}"

    expect(response).to have_http_status(:not_found)
    expect(BankAccount.find(bank_account.id)).to eq(bank_account)
  end

  it "PATCH /bank_accounts/:id of another organization returns 404" do
    account, organization = plant_coordinator(email: "a@example.com", organization_name: "A")
    other = create_organization!(name: "B")
    bank_account = BankAccount.create_for(organization: other, name: "Alheia", compe: "001")
    sign_in_as(account, organization: organization)

    patch "/bank_accounts/#{bank_account.id}", params: { name: "Hacked" }

    expect(response).to have_http_status(:not_found)
    expect(bank_account.reload.name).to eq("Alheia")
  end

  it "submitter POST /bank_accounts persists no account and responds 404" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    expect do
      post "/bank_accounts", params: { name: "Conta Principal", compe: "001" }
    end.not_to change(BankAccount, :count)

    expect(response).to have_http_status(:not_found)
  end
end
