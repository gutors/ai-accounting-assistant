require "rails_helper"

RSpec.describe "Setup", type: :request do
  it "unauthenticated GET /setup responds 302 to /login" do
    get "/setup"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "GET /setup without focus responds 302 to /login" do
    account, organization = plant_coordinator(email: "coord@example.com")
    other = Account.create!(email: "other@example.com", google_uid: "uid-other")
    Access.create!(account: other, organization: organization, kind: :coordinator)
    sign_in_as(account, organization: organization)
    Access.where(account: account).delete_all

    get "/setup"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "GET /setup responds 200 with pt-BR headings" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('lang="pt-BR"')
    expect(response.body).to include("Contador")
    expect(response.body).to include("Arquivo do pacote")
    expect(response.body).to include("Contas bancárias")
  end

  it "GET /setup empty accountant includes Cadastre o contador" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    expect(response.body).to include("Cadastre o contador")
  end

  it "setup does not include another organization accountant name" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "A")
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    org_b.update_accountant(presentation_name: "Contador Beta")
    sign_in_as(account, organization: org_a)

    get "/setup"

    expect(response.body).not_to include("Contador Beta")
  end

  it "GET /setup empty archive includes Cole a URL da pasta do Drive" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    expect(response.body).to include("Cole a URL da pasta do Drive")
  end

  it "setup does not include another organization archive URL" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "A")
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    url = "https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl"
    org_b.update_package_archive(url)
    sign_in_as(account, organization: org_a)

    get "/setup"

    expect(response.body).not_to include(url)
  end

  it "bank picker lists twelve names in COMPE order without Outro" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    picker = response.body[%r{<select[^>]*\bid="compe"[^>]*>.*?</select>}m]
    expect(picker).to be_present

    expected = [
      [ "001", "Banco do Brasil" ],
      [ "033", "Santander" ],
      [ "041", "Banrisul" ],
      [ "077", "Inter" ],
      [ "104", "Caixa" ],
      [ "136", "Unicred" ],
      [ "237", "Bradesco" ],
      [ "260", "Nubank" ],
      [ "290", "PagBank/PagSeguro" ],
      [ "341", "Itaú" ],
      [ "748", "Sicredi" ],
      [ "756", "Sicoob" ]
    ]
    options = picker.scan(%r{<option value="([^"]+)">([^<]+)</option>})
    expect(options).to eq(expected)
    expect(response.body).not_to include("Outro")
  end

  it "GET /setup with zero bank accounts includes Nenhuma conta bancaria" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    expect(response.body).to include("Nenhuma conta bancária")
  end

  it "GET /setup lists bank account names in ascending order" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Zeta", compe: "001")
    BankAccount.create_for(organization: organization, name: "Alfa", compe: "001")

    get "/setup"

    expect(response.body.index("Alfa")).to be < response.body.index("Zeta")
  end

  it "setup shows Desativar or Reativar and no delete control" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    active = BankAccount.create_for(organization: organization, name: "Ativa", compe: "001")
    inactive = BankAccount.create_for(organization: organization, name: "Parada", compe: "033")
    inactive.apply_from(active: false)

    get "/setup"

    expect(active).to be_active
    expect(response.body).to include("Desativar")
    expect(response.body).to include("Reativar")
    expect(response.body).not_to include("Excluir")
  end

  it "setup does not list another organization bank account names" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "A")
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    BankAccount.create_for(organization: org_b, name: "Conta Só B", compe: "001")
    sign_in_as(account, organization: org_a)

    get "/setup"

    expect(response.body).not_to include("Conta Só B")
  end

  it "submitter GET /setup responds 404 and omits bank-account name" do
    _coord, organization = plant_coordinator
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    get "/setup"

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("Conta Principal")
  end
end
