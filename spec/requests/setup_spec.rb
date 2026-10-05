require "rails_helper"

RSpec.describe "Setup", type: :request do
  include ActiveSupport::Testing::TimeHelpers

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

  it "GET /setup with no SEFAZ certificate includes Certificado SEFAZ and Nenhum certificado" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Certificado SEFAZ")
    expect(response.body).to include("Nenhum certificado")
  end

  it "GET /setup empty accountant includes Cadastre o contador" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    expect(response.body).to include("Cadastre o contador")
  end

  it "GET /setup cadastro accountant form is writable with CPF/CNPJ labels" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    expect(response).to have_http_status(:ok)
    expect_accountant_cadastro(response.body)
  end

  it "GET /setup leitura accountant fields are readonly with formatted CNPJ" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    persist_standing_accountant(organization)

    get "/setup"

    expect(response).to have_http_status(:ok)
    expect_accountant_leitura_cnpj_row(response.body)
  end

  it "GET /setup leitura formats CPF and empty razao social" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_accountant(presentation_name: "Ana", tax_id: "39053344705")

    get "/setup"

    tax_id = accountant_form(response.body).at_css("#tax_id")
    legal_name = accountant_form(response.body).at_css("#legal_name")
    expect(tax_id["readonly"]).to eq("readonly")
    expect(tax_id["value"]).to eq("390.533.447-05")
    expect(legal_name["readonly"]).to eq("readonly")
    expect(legal_name["value"]).to eq("")
  end

  it "GET /setup leitura with blank optionals still has Editar" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_accountant(presentation_name: "Ana")

    get "/setup"

    form = accountant_form(response.body)
    accountant_input_ids.each do |id|
      expect(form.at_css("##{id}")["readonly"]).to eq("readonly")
    end
    expect(form.at_css("#tax_id")["value"]).to eq("")
    expect(accountant_edit_control(response.body).text.strip).to eq("Editar")
  end

  it "GET /setup leitura does not persist tax id punctuation" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    persist_standing_accountant(organization)

    get "/setup"
    expect(organization.reload.accountant_tax_id).to eq("11222333000181")

    organization.update_accountant(presentation_name: "Ana", tax_id: "39053344705")
    get "/setup"
    expect(organization.reload.accountant_tax_id).to eq("39053344705")
  end

  it "GET of Contador Editar unlocks the writable accountant form" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    persist_standing_accountant(organization)

    get "/setup"
    edit_url = accountant_edit_control(response.body)["href"]

    get edit_url

    expect(response).to have_http_status(:ok)
    form = accountant_form(response.body)
    expect(form.at_css('input[type="submit"][value="Salvar contador"]')).to be_present
    accountant_input_ids.each do |id|
      expect(form.at_css("##{id}")["readonly"]).to be_nil
    end
    expect(form.at_css("#tax_id")["value"]).to eq("11222333000181")
    expect_accountant_labels(response.body)
    expect(accountant_edit_control(response.body)).to be_nil
  end

  it "setup does not include another organization accountant name" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
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
    org_b = create_organization!(name: "B")
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
    bank_rows = rows_html(response.body, "bank-account")
    expect(bank_rows.join).not_to include("Excluir")
  end

  it "setup does not list another organization bank account names" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    BankAccount.create_for(organization: org_b, name: "Conta Só B", compe: "001")
    sign_in_as(account, organization: org_a)

    get "/setup"

    expect(response.body).not_to include("Conta Só B")
  end

  it "submitter GET /setup responds 404 and omits titular CNPJ" do
    _coord, organization = plant_coordinator
    sign_in_as(_coord, organization: organization)
    organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    get "/setup"

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("11.222.333/0001-81")
    expect(response.body).not_to include("Válido até")
  end

  it "GET /setup with certificate includes Remover turbo confirm" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")

    get "/setup"

    expect(response.body).to include("Remover")
    expect(response.body).to include('data-turbo-confirm="Remover o certificado SEFAZ?"')
  end

  it "setup does not include another organization titular CNPJ" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    org_b.install_sefaz_certificate(
      file: sefaz_pfx(titular: "12345678000101", name: "b.pfx"),
      passphrase: "passphrase-secreta"
    )
    sign_in_as(account, organization: org_a)

    get "/setup"

    expect(response.body).not_to include("12.345.678/0001-01")
  end

  it "GET /setup with expired certificate includes Expirado em 11/05/2026" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    travel_to Date.new(2026, 5, 11) do
      organization.install_sefaz_certificate(
        file: sefaz_pfx(not_after: Date.new(2026, 5, 11), name: "expiring.pfx"),
        passphrase: "passphrase-secreta"
      )
    end

    travel_to Date.new(2026, 5, 12) do
      get "/setup"
    end

    expect(response.body).to include("Expirado em 11/05/2026")
    expect(response.body).not_to include("Válido até")
  end

  it "GET /setup with blank wrap key and no certificate includes Nenhum certificado" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    with_env("SEFAZ_WRAP_KEY" => nil) do
      get "/setup"
    end

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Nenhum certificado")
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

  it "GET /setup with zero extra exception kinds includes Tipos extras de excecao and Nenhum tipo extra" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Tipos extras de exceção")
    expect(response.body).to include("Nenhum tipo extra")
  end

  it "GET /setup lists extra exception kinds Alfa before Zeta" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ExtraExceptionKind.create_for(organization: organization, name: "Zeta")
    ExtraExceptionKind.create_for(organization: organization, name: "Alfa")

    get "/setup"

    expect(response.body.index("Alfa")).to be < response.body.index("Zeta")
  end

  it "setup extra exception kind has no control that submits a new name" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ExtraExceptionKind.create_for(organization: organization, name: "Doação")

    get "/setup"

    row = extra_kind_row(response.body, "Doação")
    expect(row).to be_present
    expect(row).not_to include('name="name"')
  end

  it "GET /setup does not list Tarifa bancaria or Honorario do contador as extra exception kinds" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    extras = extra_kinds_section(response.body)
    expect(extras).not_to include("Tarifa bancária")
    expect(extras).not_to include("Honorário do contador")
  end

  it "setup extra exception kinds show Desativar or Reativar" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ExtraExceptionKind.create_for(organization: organization, name: "Ativa Extra")
    inactive = ExtraExceptionKind.create_for(organization: organization, name: "Parada Extra")
    inactive.apply_active(false)

    get "/setup"

    expect(extra_kind_row(response.body, "Ativa Extra")).to include("Desativar")
    expect(extra_kind_row(response.body, "Parada Extra")).to include("Reativar")
  end

  it "setup unused extra exception kind Folha includes Excluir" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ExtraExceptionKind.create_for(organization: organization, name: "Folha")

    get "/setup"

    expect(extra_kind_row(response.body, "Folha")).to include("Excluir")
  end

  it "setup includes no Excluir while every extra exception kind is referenced" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    _month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    payment.update!(extra_exception_kind: kind)

    get "/setup"

    expect(response.body).not_to include("Excluir")
  end

  it "setup does not list another organization extra exception kind" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    ExtraExceptionKind.create_for(organization: org_b, name: "Só B Extra")
    sign_in_as(account, organization: org_a)

    get "/setup"

    expect(response.body).not_to include("Só B Extra")
  end

  it "setup h1 is Configuracao and bank account edit folds under Editar" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")

    get "/setup"

    expect(response).to have_http_status(:ok)
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("Configuração")
    account_row = row(response.body, "bank-account", bank_account_id: bank_account.id)
    expect(account_row).not_to be_nil
    form = account_row.css("form").find { |node| node["action"] == "/bank_accounts/#{bank_account.id}" && node.at_css('input[name="_method"][value="patch"]') && node.at_css('input[name="name"]') }
    expect(form).not_to be_nil
    details = form.ancestors("details").first
    expect(details).not_to be_nil
    expect(details.at_css("summary").text.strip).to eq("Editar")
  end

  def extra_kind_row(body, name)
    rows_html(body, "extra-exception-kind").find { |li| li.include?(name) }
  end

  def extra_kinds_section(body)
    start = body.index("Tipos extras de exceção")
    body[start..]
  end
end
