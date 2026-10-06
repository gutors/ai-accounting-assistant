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
    expect(response.body).to include("Armazenamento do pacote mensal")
    expect(response.body).to include("Contas bancárias")
  end

  it "GET /setup with no SEFAZ certificate includes A1 heading and empty line" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    expect(response).to have_http_status(:ok)
    expect_certificate_absent_copy(response.body)
  end

  it "GET /setup with no SEFAZ certificate keeps Arquivo and Senha in closed Instalar certificado details" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    expect_certificate_install_fold(response.body, open: false)
  end

  it "GET setup A1 form has Limpar next to certificate" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    form = certificate_install_details(response.body).at_css('form[action="/sefaz_certificate"]')
    certificate = form.at_css("#certificate")
    limpar = certificate.parent.css("button").select { |button| button.text.strip == "Limpar" && button["type"] == "button" }
    expect(limpar.size).to eq(1)
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

  it "GET /setup leitura accountant fields are labeled text with formatted CNPJ" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    persist_standing_accountant(organization)

    get "/setup"

    expect(response).to have_http_status(:ok)
    expect_accountant_leitura_cnpj_row(response.body)
    expect(accountant_section(response.body).at_css("div.grid")["class"]).to include("md:grid-cols-2")
  end

  it "GET /setup leitura formats CPF and empty razao social" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_accountant(presentation_name: "Ana", tax_id: "39053344705")

    get "/setup"

    section = accountant_section(response.body)
    expect(section.at_css("p#tax_id").text.strip).to eq("390.533.447-05")
    expect(section.at_css("p#legal_name").text.strip).to eq("")
  end

  it "GET /setup leitura with blank optionals still has Editar" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_accountant(presentation_name: "Ana")

    get "/setup"

    section = accountant_section(response.body)
    %w[tax_id legal_name pix_key destination_email].each do |id|
      expect(section.at_css("p##{id}").text.strip).to eq("")
    end
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

  it "GET /setup cadastro archive form is writable with Google Drive copy" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    expect(response).to have_http_status(:ok)
    expect_archive_cadastro(response.body)
    headings = page_doc(response.body).css("h2").map { |node| node.text.strip }
    expect(headings.index("Contador")).to be < headings.index("Armazenamento do pacote mensal")
    expect(headings.index("Armazenamento do pacote mensal")).to be < headings.index(certificate_heading)
  end

  it "GET /setup leitura archive is labeled text" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    persist_standing_archive(organization)

    get "/setup"

    expect(response).to have_http_status(:ok)
    expect_archive_leitura(response.body)
  end

  it "GET of Armazenamento Editar unlocks the writable archive form" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    persist_standing_archive(organization)

    get "/setup"
    edit_url = archive_edit_control(response.body)["href"]

    get edit_url

    expect(response).to have_http_status(:ok)
    expect_archive_edicao(response.body)
  end

  it "GET /setup edit=package_archive unlocks archive and keeps accountant leitura" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    persist_standing_accountant(organization)
    persist_standing_archive(organization)

    get "/setup?edit=package_archive"

    expect(response).to have_http_status(:ok)
    expect_archive_edicao(response.body)
    expect_accountant_leitura_cnpj_row(response.body)
  end

  it "GET /setup edit=accountant unlocks accountant and keeps archive leitura" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    persist_standing_accountant(organization)
    persist_standing_archive(organization)

    get "/setup?edit=accountant"

    expect(response).to have_http_status(:ok)
    form = accountant_form(response.body)
    expect(form.at_css('input[type="submit"][value="Salvar contador"]')).to be_present
    accountant_input_ids.each do |id|
      input = form.at_css("input##{id}")
      expect(input["class"]).to include("border-rule")
      expect(input["class"]).to include("bg-sheet")
      expect(input["readonly"]).to be_nil
      expect(input["disabled"]).to be_nil
    end
    expect(form.at_css("#tax_id")["value"]).to eq("11222333000181")
    expect(form["class"]).to include("md:grid-cols-2")
    expect(accountant_section(response.body).at_css("p#presentation_name")).to be_nil
    expect_archive_leitura(response.body)
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

  it "GET /setup with no bank accounts includes empty line and add form labelled Agencia/Conta Corrente" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    expect(response).to have_http_status(:ok)
    section = bank_accounts_section(response.body)
    expect(section.text).to include("Nenhuma conta bancária")
    expect(section.css('li[data-row="bank-account"]')).to be_empty
    expect(section.to_html).not_to include("Coordenadas")
    expect_bank_account_add_form(response.body)
  end

  it "GET /setup lists bank accounts as four cells without Coordenadas or column headers" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    principal = BankAccount.create_for(
      organization: organization, name: "Conta Principal", compe: "001", coordinates: "ag 1234"
    )
    parada = BankAccount.create_for(organization: organization, name: "Parada", compe: "033")
    parada.apply_from(active: false)
    BankAccount.create_for(organization: organization, name: "Zeta", compe: "001")
    BankAccount.create_for(organization: organization, name: "Alfa", compe: "001")

    get "/setup"

    principal_row = row(response.body, "bank-account", bank_account_id: principal.id)
    parada_row = row(response.body, "bank-account", bank_account_id: parada.id)
    expect(principal_row).to be_present
    expect(parada_row).to be_present
    expect(response.body.index("Alfa")).to be < response.body.index("Zeta")
    principal_html = principal_row.to_html
    expect(principal_html.index("Banco do Brasil")).to be < principal_html.index("Conta Principal")
    expect(principal_html.index("Conta Principal")).to be < principal_html.index("ag 1234")
    expect(principal_html.index("ag 1234")).to be < principal_html.index("extrato-conta-principal")
    parada_html = parada_row.to_html
    expect(parada_html.index("Santander")).to be < parada_html.index("Parada")
    expect(parada_html.index("Parada")).to be < parada_html.index("extrato-parada")
    expect(parada_html).to include("Inativa")
    expect(principal_html).not_to include("Coordenadas")
    expect(parada_html).not_to include("Coordenadas")
    section = bank_accounts_section(response.body)
    headerish = section.css("li, tr, thead").find do |node|
      text = node.text
      text.include?("Nome do Banco") && text.include?("Nome") &&
        text.include?("Agência/Conta Corrente") && text.include?("extrato-{slug}")
    end
    expect(headerish).to be_nil
  end

  it "GET /setup listed accounts have one add section form and row Editar on /setup" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    principal = BankAccount.create_for(
      organization: organization, name: "Conta Principal", compe: "001", coordinates: "ag 1234"
    )
    parada = BankAccount.create_for(organization: organization, name: "Parada", compe: "033")
    parada.apply_from(active: false)

    get "/setup"

    section = bank_accounts_section(response.body)
    forms = section.css("form").select { |form| form.at_css("#name") && form.at_css("#compe") && form.at_css("#coordinates") }
    expect(forms.size).to eq(1)
    expect_bank_account_add_form(response.body)
    picker = forms.first.at_css("select#compe")
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
    expect(picker.css("option").map { |option| [ option["value"], option.text ] }).to eq(expected)
    expect(section.to_html).not_to include("Outro")
    expect(section.css("details").any? { |details| details.at_css("summary")&.text&.strip == "Editar" }).to eq(false)
    [ principal, parada ].each do |bank_account|
      listed = row(response.body, "bank-account", bank_account_id: bank_account.id)
      edit = bank_account_row_edit_control(listed)
      expect(edit.text.strip).to eq("Editar")
      expect(edit["href"]).to include("/setup")
    end
    section.css("form").each do |form|
      next unless form.at_css('input[type="submit"][value="Desativar"], input[type="submit"][value="Reativar"]') ||
        form.text.include?("Desativar") || form.text.include?("Reativar")

      expect(form.at_css("#name")).to be_nil
    end
  end

  it "GET of row Editar fills the section form as PATCH Salvar conta" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    principal = BankAccount.create_for(
      organization: organization, name: "Conta Principal", compe: "001", coordinates: "ag 1234"
    )
    parada = BankAccount.create_for(organization: organization, name: "Parada", compe: "033")
    parada.apply_from(active: false)

    get "/setup"
    edit_url = bank_account_row_edit_control(row(response.body, "bank-account", bank_account_id: principal.id))["href"]

    get edit_url

    expect(response).to have_http_status(:ok)
    expect(row(response.body, "bank-account", bank_account_id: principal.id)).to be_present
    expect(row(response.body, "bank-account", bank_account_id: parada.id)).to be_present
    form = bank_account_section_form(response.body)
    expect(form["action"]).to eq("/bank_accounts/#{principal.id}")
    expect(form.at_css('input[name="_method"][value="patch"]')).to be_present
    expect(form.at_css('input[type="submit"][value="Salvar conta"]')).to be_present
    expect(form.at_css("#name")["value"]).to eq("Conta Principal")
    expect(selected_compe(form)).to eq("001")
    expect(form.at_css("#coordinates")["value"]).to eq("ag 1234")
    expect_bank_account_field_labels(form)
    named_forms = bank_accounts_section(response.body).css("form").select { |node| node.at_css("#name") }
    expect(named_forms.size).to eq(1)
  end

  it "GET /setup edit bank_account of another organization stays the add form" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    alheia = BankAccount.create_for(organization: org_b, name: "Alheia", compe: "001")
    sign_in_as(account, organization: org_a)

    get "/setup?edit=bank_account&bank_account_id=#{alheia.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Alheia")
    expect_bank_account_add_form(response.body)
  end

  it "GET /setup edit bank_account with unknown id stays the add form" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup?edit=bank_account&bank_account_id=0"

    expect(response).to have_http_status(:ok)
    expect_bank_account_add_form(response.body)
  end

  it "GET /setup listed accounts show Desativar or Reativar and no Excluir" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    principal = BankAccount.create_for(
      organization: organization, name: "Conta Principal", compe: "001", coordinates: "ag 1234"
    )
    parada = BankAccount.create_for(organization: organization, name: "Parada", compe: "033")
    parada.apply_from(active: false)

    get "/setup"

    expect(row(response.body, "bank-account", bank_account_id: principal.id).to_html).to include("Desativar")
    parada_html = row(response.body, "bank-account", bank_account_id: parada.id).to_html
    expect(parada_html).to include("Reativar")
    expect(parada_html).to include("Inativa")
    expect(bank_accounts_section(response.body).to_html).not_to include("Excluir")
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

  it "GET /setup with listed A1 shows titular validity Remover outside closed install details" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")

    get "/setup"

    expect(response).to have_http_status(:ok)
    expect_certificate_listed_cnpj_row(response.body)
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
    expect(response.body).to include("Remover")
    expect(response.body).not_to include("Válido até")
    expect_certificate_install_fold(response.body, open: false)
  end

  it "GET /setup with blank wrap key and no certificate includes the empty A1 line" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    with_env("SEFAZ_WRAP_KEY" => nil) do
      get "/setup"
    end

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(certificate_empty_line)
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

  it "GET /setup with zero extra exception kinds lists fixed Tarifa then Honorario" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    expect(response).to have_http_status(:ok)
    section = extras_section(response.body)
    expect(page_doc(response.body).css("div.space-y-12 > section > h2").last.text.strip).to eq("Tipos extras de exceção")
    expect(section.at_css("h2 + ul")).to be_present
    expect(section.at_css("h2 + p")).to be_nil
    html = section.to_html
    heading = html.index("Tipos extras de exceção")
    tarifa = html.index("Tarifa bancária")
    tarifa_copy = html.index("Tarifa cobrada pelo banco; não há documento fiscal a anexar.")
    honorario = html.index("Honorário do contador")
    honorario_copy = html.index("Honorário do contador neste fechamento; isento de documento de suporte.")
    expect(heading).to be_present
    expect(tarifa).to be_present
    expect(tarifa_copy).to be_present
    expect(honorario).to be_present
    expect(honorario_copy).to be_present
    expect(heading).to be < tarifa
    expect(tarifa).to be < tarifa_copy
    expect(tarifa_copy).to be < honorario
    expect(honorario).to be < honorario_copy
    expect(html).not_to include("Nenhum tipo extra")
    expect(organization.extra_exception_kinds.count).to eq(0)
  end

  it "GET /setup Tarifa and Honorario are not extra-exception-kind rows" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ExtraExceptionKind.create_for(
      organization: organization, name: "Doação", justification: "Doação pontual sem nota."
    )

    get "/setup"

    extra_names = rows(response.body, "extra-exception-kind").map { |node| node.text }
    expect(extra_names.join).to include("Doação")
    expect(extra_names.join).not_to include("Tarifa bancária")
    expect(extra_names.join).not_to include("Honorário do contador")
    expect(extras_section(response.body).text).to include("Tarifa bancária")
    expect(extras_section(response.body).text).to include("Honorário do contador")
  end

  it "GET /setup fixed exception rows omit Desativar Reativar Excluir" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    tarifa = base_exception_row(response.body, "Tarifa bancária")
    honorario = base_exception_row(response.body, "Honorário do contador")
    expect(tarifa).to be_present
    expect(honorario).to be_present
    [ tarifa, honorario ].each do |row|
      expect(row.text).not_to include("Desativar")
      expect(row.text).not_to include("Reativar")
      expect(row.text).not_to include("Excluir")
    end
  end

  it "GET /setup extras section order is Tarifa Honorario Alfa Zeta" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ExtraExceptionKind.create_for(
      organization: organization, name: "Zeta", justification: "Isento de documento de suporte."
    )
    ExtraExceptionKind.create_for(
      organization: organization, name: "Alfa", justification: "Isento de documento de suporte."
    )

    get "/setup"

    html = extras_section(response.body).to_html
    expect(html.index("Tarifa bancária")).to be < html.index("Honorário do contador")
    expect(html.index("Honorário do contador")).to be < html.index("Alfa")
    expect(html.index("Alfa")).to be < html.index("Zeta")
  end

  it "GET /setup extra kind form has Nome Justificativa and Adicionar tipo extra" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/setup"

    section = extras_section(response.body)
    form = section.at_css('form[action="/extra_exception_kinds"]')
    expect(form.at_css('label[for="extra_exception_kind_name"]').text.strip).to eq("Nome")
    expect(form.at_css("#extra_exception_kind_name")).to be_present
    justification = form.at_css('input[name="justification"]')
    expect(justification).to be_present
    expect(form.at_css("label[for='#{justification['id']}']").text.strip).to eq("Justificativa")
    expect(form.at_css('input[type="submit"][value="Adicionar tipo extra"]')).to be_present
    heading = section.at_css('li[data-row="extras-column-headings"]')
    expect(heading.text.gsub(/\s+/, " ").strip).to eq("Justificativa")
    expect(heading.ancestors("form")).to be_empty
    list = section.at_css("h2 + ul")
    expect(list.css("li").first["data-row"]).to eq("extras-column-headings")
    expect(form.previous_element).to eq(list)
  end

  it "setup extra exception kind row shows justification and has no name or justification fields" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ExtraExceptionKind.create_for(
      organization: organization, name: "Doação", justification: "Doação pontual sem nota."
    )

    get "/setup"

    row = extra_kind_row(response.body, "Doação")
    expect(row).to be_present
    expect(row.text).to include("Doação pontual sem nota.")
    expect(row.at_css('input[name="name"], textarea[name="name"], select[name="name"]')).to be_nil
    expect(row.at_css('input[name="justification"], textarea[name="justification"]')).to be_nil
  end

  it "setup deactivated extra exception kind still includes justification" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(
      organization: organization, name: "Doação", justification: "Doação pontual sem nota."
    )
    kind.apply_active(false)

    get "/setup"

    row = extra_kind_row(response.body, "Doação")
    expect(row.text).to include("Doação pontual sem nota.")
  end

  it "setup extra exception kinds show Desativar or Reativar" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ExtraExceptionKind.create_for(
      organization: organization, name: "Ativa Extra", justification: "Isento de documento de suporte."
    )
    inactive = ExtraExceptionKind.create_for(
      organization: organization, name: "Parada Extra", justification: "Isento de documento de suporte."
    )
    inactive.apply_active(false)

    get "/setup"

    expect(extra_kind_row(response.body, "Ativa Extra").text).to include("Desativar")
    expect(extra_kind_row(response.body, "Parada Extra").text).to include("Reativar")
  end

  it "setup unused extra exception kind Folha includes Excluir" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ExtraExceptionKind.create_for(
      organization: organization, name: "Folha", justification: "Isento de documento de suporte."
    )

    get "/setup"

    expect(extra_kind_row(response.body, "Folha").text).to include("Excluir")
  end

  it "setup includes no Excluir while every extra exception kind is referenced" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(
      organization: organization, name: "Doação", justification: "Doação pontual sem nota."
    )
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
    ExtraExceptionKind.create_for(
      organization: org_b, name: "Só B Extra", justification: "Isento de documento de suporte."
    )
    sign_in_as(account, organization: org_a)

    get "/setup"

    expect(response.body).not_to include("Só B Extra")
  end

  it "setup h1 is Configuracao and bank account Editar fills the section form" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")

    get "/setup"

    expect(response).to have_http_status(:ok)
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("Configuração")
    account_row = row(response.body, "bank-account", bank_account_id: bank_account.id)
    expect(account_row).not_to be_nil
    expect(account_row.at_css("details")).to be_nil
    edit = bank_account_row_edit_control(account_row)
    expect(edit["href"]).to include("/setup")
    expect(bank_accounts_section(response.body).css("details").any? { |details| details.at_css("summary")&.text&.strip == "Editar" }).to eq(false)

    get edit["href"]

    form = bank_account_section_form(response.body)
    expect(form["action"]).to eq("/bank_accounts/#{bank_account.id}")
    expect(form.at_css('input[name="_method"][value="patch"]')).to be_present
    expect(form.at_css('input[type="submit"][value="Salvar conta"]')).to be_present
  end
end
