require "rails_helper"

RSpec.describe "Setup desk", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  def plant_gaps(organization)
    persist_standing_accountant(organization)
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "033")
    travel_to Date.new(2026, 5, 11) do
      organization.install_sefaz_certificate(
        file: sefaz_pfx(not_after: Date.new(2026, 5, 11), name: "expiring.pfx"),
        passphrase: "passphrase-secreta"
      )
    end
  end

  def signed_setup(organization_name: "ONG Norte")
    account, organization = plant_coordinator(organization_name: organization_name)
    sign_in_as(account, organization: organization)
    [ account, organization ]
  end

  it "setup index lists five items in order" do
    _account, organization = signed_setup
    plant_gaps(organization)

    get "/setup"

    expect(response).to have_http_status(:ok)
    index = page_doc(response.body).at_css('[data-desk="index"]')
    expect(index.at_css("h2").text.strip).to eq("Configuração")
    titles = setup_index(response.body).css(".desk-item-title").map { |node| node.text.strip }
    expect(titles).to eq([
      "Contador", "Arquivo do pacote", "Certificado A1", "Contas bancárias", "Tipos extras"
    ])
  end

  it "complete Contador row is Cadastrado without red margin" do
    _account, organization = signed_setup
    persist_standing_accountant(organization)

    get "/setup"

    row = setup_index_row(response.body, "Contador")
    expect(row.text).to include("Ana Contábil")
    expect(row.text).to include("Cadastrado")
    expect(row["class"].to_s).not_to include("is-block")
    expect(row.to_html).not_to include("text-margem")
  end

  it "blank Contador row is Falta in margem with red margin" do
    _account, _organization = signed_setup

    get "/setup?item=accountant"

    row = setup_index_row(response.body, "Contador")
    expect(row.at_css(".text-margem").text.strip).to eq("Falta")
    expect(row["class"]).to include("is-block")
  end

  it "blank archive row is Falta in margem with red margin" do
    _account, _organization = signed_setup

    get "/setup"

    row = setup_index_row(response.body, "Arquivo do pacote")
    expect(row.text).to include("Pasta do Drive")
    expect(row.at_css(".text-margem").text.strip).to eq("Falta")
    expect(row["class"]).to include("is-block")
  end

  it "expired A1 row is Expirado in margem with red margin" do
    _account, organization = signed_setup
    plant_gaps(organization)

    travel_to Date.new(2026, 5, 12) do
      get "/setup"
    end

    row = setup_index_row(response.body, "Certificado A1")
    expect(row.text).to include("Consulta SEFAZ")
    expect(row.at_css(".text-margem").text.strip).to eq("Expirado")
    expect(row["class"]).to include("is-block")
  end

  it "missing A1 row is Falta in margem with red margin" do
    _account, _organization = signed_setup

    get "/setup"

    row = setup_index_row(response.body, "Certificado A1")
    expect(row.at_css(".text-margem").text.strip).to eq("Falta")
    expect(row["class"]).to include("is-block")
  end

  it "valid A1 row is Instalado without red margin" do
    _account, organization = signed_setup
    organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")

    get "/setup"

    row = setup_index_row(response.body, "Certificado A1")
    expect(row.text).to include("Instalado")
    expect(row["class"].to_s).not_to include("is-block")
    expect(row.to_html).not_to include("text-margem")
  end

  it "two bank accounts row is 2 contas Ativas without red margin" do
    _account, organization = signed_setup
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "033")

    get "/setup"

    row = setup_index_row(response.body, "Contas bancárias")
    expect(row.text).to include("2 contas")
    expect(row.text).to include("Ativas")
    expect(row["class"].to_s).not_to include("is-block")
    expect(row.to_html).not_to include("text-margem")
  end

  it "zero bank accounts row is Falta in margem with red margin" do
    _account, _organization = signed_setup

    get "/setup"

    row = setup_index_row(response.body, "Contas bancárias")
    expect(row.at_css(".text-margem").text.strip).to eq("Falta")
    expect(row["class"]).to include("is-block")
  end

  it "two active extras row is 2 ativos without red margin" do
    _account, _organization = signed_setup

    get "/setup"

    row = setup_index_row(response.body, "Tipos extras")
    expect(row.text).to include("2 ativos")
    expect(row["class"].to_s).not_to include("is-block")
    expect(row.to_html).not_to include("text-margem")
  end

  it "Tipos extras row never takes the red margin" do
    _account, organization = signed_setup
    organization.update!(bank_fee_exception_active: false, accountant_fee_exception_active: false)

    get "/setup"

    row = setup_index_row(response.body, "Tipos extras")
    expect(row["class"].to_s).not_to include("is-block")
    expect(row.to_html).not_to include("text-margem")
  end

  it "Arquivo do pacote row is GET item archive" do
    _account, _organization = signed_setup

    get "/setup"

    expect(setup_index_row(response.body, "Arquivo do pacote")["href"]).to eq("/setup?item=archive")
  end

  it "item certificate marks Certificado A1 current and h1" do
    _account, _organization = signed_setup

    get "/setup?item=certificate"

    current = setup_index(response.body).css("a[aria-current='true']")
    expect(current.size).to eq(1)
    expect(current.first.at_css(".desk-item-title").text.strip).to eq("Certificado A1")
    expect(setup_pane(response.body).at_css("h1").text.strip).to eq("Certificado A1")
  end

  it "item accountant cadastro has h1 Contador" do
    _account, _organization = signed_setup

    get "/setup?item=accountant"

    expect(setup_pane(response.body).at_css("h1").text.strip).to eq("Contador")
    expect_accountant_cadastro(response.body)
  end

  it "item accountant leitura has h1 Contador" do
    _account, organization = signed_setup
    persist_standing_accountant(organization)

    get "/setup?item=accountant"

    expect(setup_pane(response.body).at_css("h1").text.strip).to eq("Contador")
    expect_accountant_leitura_cnpj_row(response.body)
  end

  it "item banks has h1 Contas bancarias sheet and Adicionar conta" do
    _account, organization = signed_setup
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")

    get "/setup?item=banks"

    pane = setup_pane(response.body)
    expect(pane.at_css("h1").text.strip).to eq("Contas bancárias")
    expect(pane.at_css('li[data-row="bank-account"]')).to be_present
    expect(bank_account_add_details(response.body).at_css("summary").text.strip).to eq("Adicionar conta")
  end

  it "item extras has h1 Tipos extras sheet and Adicionar tipo extra" do
    _account, _organization = signed_setup

    get "/setup?item=extras"

    pane = setup_pane(response.body)
    expect(pane.at_css("h1").text.strip).to eq("Tipos extras")
    expect(pane.at_css('li[data-row="base-document-exception"]')).to be_present
    expect(extra_kind_add_details(response.body).at_css("summary").text.strip).to eq("Adicionar tipo extra")
  end

  it "default GET setup selects archive when it is the first Falta" do
    _account, organization = signed_setup
    persist_standing_accountant(organization)

    get "/setup"

    expect(setup_index_row(response.body, "Arquivo do pacote")["aria-current"]).to eq("true")
    expect(setup_pane(response.body).at_css("h1").text.strip).to eq("Arquivo do pacote")
  end

  it "edit accountant selects Contador and opens the writable form" do
    _account, organization = signed_setup
    persist_standing_accountant(organization)

    get "/setup?edit=accountant"

    expect(setup_index_row(response.body, "Contador")["aria-current"]).to eq("true")
    form = accountant_form(response.body)
    expect(form.at_css('input[type="submit"][value="Salvar contador"]')).to be_present
    accountant_input_ids.each do |id|
      expect(form.at_css("##{id}")["readonly"]).to be_nil
    end
  end

  it "edit package_archive selects Arquivo and opens the writable form" do
    _account, organization = signed_setup
    persist_standing_accountant(organization)
    persist_standing_archive(organization)

    get "/setup?edit=package_archive"

    expect(setup_index_row(response.body, "Arquivo do pacote")["aria-current"]).to eq("true")
    expect_archive_edicao(response.body)
  end

  it "edit bank_account selects Contas and opens that row form" do
    _account, organization = signed_setup
    principal = BankAccount.create_for(
      organization: organization, name: "Conta Principal", compe: "001", coordinates: "ag 1234"
    )

    get "/setup?edit=bank_account&bank_account_id=#{principal.id}"

    expect(setup_index_row(response.body, "Contas bancárias")["aria-current"]).to eq("true")
    form = bank_account_section_form(response.body)
    expect(form["action"]).to eq("/bank_accounts/#{principal.id}")
    expect(form.at_css('input[type="submit"][value="Salvar conta"]')).to be_present
    expect(bank_account_add_details(response.body).has_attribute?("open")).to eq(true)
  end

  it "blank archive pane Cole a URL in margem and Salvar arquivo" do
    _account, organization = signed_setup
    persist_standing_accountant(organization)

    get "/setup"

    pane = setup_pane(response.body)
    prompt = pane.css("p").find { |node| node.text.strip == "Cole a URL da pasta do Google Drive" }
    expect(prompt["class"]).to include("text-margem")
    expect(prompt["class"]).to include("border-margem")
    url = archive_form(response.body).at_css("#url")
    expect(url["placeholder"]).to eq("https://drive.google.com/drive/folders/…")
    expect(archive_form(response.body).at_css('input[type="submit"][value="Salvar arquivo"]')).to be_present
  end

  it "missing A1 pane includes the empty install line" do
    _account, _organization = signed_setup

    get "/setup?item=certificate"

    expect(setup_pane(response.body).text).to include(certificate_empty_line)
  end

  it "blank Contador pane includes Cadastre o contador" do
    _account, _organization = signed_setup

    get "/setup?item=accountant"

    expect_accountant_cadastro(response.body)
  end

  it "setup omits stacked chapter headings and space-y-12" do
    _account, _organization = signed_setup

    get "/setup"

    expect(response.body).not_to include("Armazenamento do pacote mensal")
    expect(response.body).not_to include("Certificado Digital A1 - Para consulta na SEFAZ")
    expect(response.body).not_to include("Tipos extras de exceção")
    expect(page_doc(response.body).at_css("div.space-y-12")).to be_nil
  end

  it "setup main is a two-column grid with first column 26rem" do
    _account, _organization = signed_setup

    get "/setup"

    expect(page_doc(response.body).at_css("main")["class"]).to include("md:grid-cols-[26rem_1fr]")
  end
end
