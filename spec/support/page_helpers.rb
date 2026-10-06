# Markup anchors for request specs: rows and notices are located through data-* hooks, never class strings.
module PageHelpers
  def page_doc(body)
    Nokogiri::HTML(body)
  end

  def error_notice(body)
    page_doc(body).at_css('p[role="alert"][data-notice="error"]')
  end

  def error_notice_text(body)
    error_notice(body)&.text&.strip
  end

  def toast_node(body)
    page_doc(body).at_css("[data-toast]")
  end

  def turbo_stream_accept
    { "Accept" => "text/vnd.turbo-stream.html, text/html" }
  end

  def turbo_stream_nodes(body)
    Nokogiri::HTML::DocumentFragment.parse(body).css("turbo-stream")
  end

  def turbo_stream_for(body, css_selector)
    turbo_stream_nodes(body).find { |node| node["targets"] == css_selector }
  end

  def rows(body, name)
    page_doc(body).css(%(li[data-row="#{name}"]))
  end

  def pending_invite_item(body, email)
    rows(body, "invite").find { |node| node.text.include?(email) }
  end

  def row(body, name, **attrs)
    selector = attrs.map { |key, value| %([data-#{key.to_s.tr('_', '-')}="#{value}"]) }.join
    page_doc(body).at_css(%(li[data-row="#{name}"]#{selector}))
  end

  def rows_html(body, name)
    rows(body, name).map(&:to_html)
  end

  STANDING_ARCHIVE_URL = "https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl"

  def accountant_section(body)
    page_doc(body).css("section").find { |section| section.at_css("h2")&.text&.strip == "Contador" }
  end

  def accountant_form(body)
    accountant_section(body)&.at_css('form[action="/accountant"]')
  end

  def accountant_edit_control(body)
    accountant_section(body)&.css("a, button").find { |node| node.text.strip == "Editar" }
  end

  def accountant_input_ids
    %w[presentation_name tax_id legal_name pix_key destination_email]
  end

  def persist_standing_accountant(organization)
    organization.update_accountant(
      presentation_name: "Ana Contábil",
      tax_id: "11222333000181",
      legal_name: "Contábil LTDA",
      pix_key: "chave-pix",
      destination_email: "ana@example.com"
    )
  end

  def persist_standing_archive(organization, url: STANDING_ARCHIVE_URL)
    organization.update_package_archive(url)
  end

  def archive_section(body)
    page_doc(body).css("section").find { |section| section.at_css("h2")&.text&.strip == "Armazenamento do pacote mensal" }
  end

  def archive_form(body)
    archive_section(body)&.at_css('form[action="/package_archive"]')
  end

  def archive_edit_control(body)
    archive_section(body)&.css("a, button").find { |node| node.text.strip == "Editar" }
  end

  def extras_section(body)
    page_doc(body).css("section").find { |section| section.at_css("h2")&.text&.strip == "Tipos extras de exceção" }
  end

  def extra_kind_row(body, name)
    rows(body, "extra-exception-kind").find { |node| node.text.include?(name) }
  end

  def base_exception_row(body, name)
    rows(body, "base-document-exception").find { |node| node.text.include?(name) }
  end

  def expect_accountant_labels(body)
    expect(page_doc(body).at_css('label[for="presentation_name"]').text.strip).to eq("Nome de apresentação")
    expect(page_doc(body).at_css('label[for="tax_id"]').text.strip).to eq("CPF/CNPJ (preencher apenas números)")
    expect(page_doc(body).at_css('label[for="legal_name"]').text.strip).to eq("Razão social")
    expect(page_doc(body).at_css('label[for="pix_key"]').text.strip).to eq("PIX")
    expect(page_doc(body).at_css('label[for="destination_email"]').text.strip).to eq("Email para envio")
  end

  def expect_accountant_cadastro(body)
    expect(body).to include("Cadastre o contador")
    form = accountant_form(body)
    expect(form.at_css('input[type="submit"][value="Salvar contador"]')).to be_present
    accountant_input_ids.each do |id|
      input = form.at_css("##{id}")
      expect(input).to be_present
      expect(input["readonly"]).to be_nil
    end
    expect(form["class"]).to include("md:grid-cols-2")
    expect_accountant_labels(body)
    expect(body).not_to include("Id fiscal")
    expect(body).not_to include("Destino do pacote")
    expect(accountant_edit_control(body)).to be_nil
  end

  def expect_accountant_leitura_cnpj_row(body)
    section = accountant_section(body)
    expect(section.at_css("input, textarea, select")).to be_nil
    {
      "presentation_name" => "Ana Contábil",
      "tax_id" => "11.222.333/0001-81",
      "legal_name" => "Contábil LTDA",
      "pix_key" => "chave-pix",
      "destination_email" => "ana@example.com"
    }.each do |id, text|
      node = section.at_css("p##{id}")
      expect(node.text.strip).to eq(text)
      expect(node["class"]).to include("font-medium")
      expect(node["class"].to_s).not_to include("border-rule")
      expect(node["class"].to_s).not_to include("bg-sheet")
    end
    expect_accountant_labels(body)
    expect(section.text).not_to include("Salvar contador")
    expect(section.text).not_to include("Cadastre o contador")
    expect(accountant_edit_control(body).text.strip).to eq("Editar")
  end

  def expect_archive_cadastro(body)
    expect(page_doc(body).css("h2").map { |node| node.text.strip }).to include("Armazenamento do pacote mensal")
    expect(body).to include("Cole a URL da pasta do Google Drive")
    form = archive_form(body)
    expect(form.at_css('input[type="submit"][value="Salvar arquivo"]')).to be_present
    url = form.at_css("input#url")
    expect(url["class"]).to include("border-rule")
    expect(url["class"]).to include("bg-sheet")
    expect(url["readonly"]).to be_nil
    expect(url["disabled"]).to be_nil
    expect(page_doc(body).at_css('label[for="url"]').text.strip).to eq("URL da pasta do Google Drive")
    section = archive_section(body)
    expect(archive_edit_control(body)).to be_nil
    expect(section.at_css('input[type="submit"][value="Confirmar"]')).to be_nil
    copy = page_doc(body).xpath("//text()").map { |node| node.text.strip }
    expect(copy).not_to include("Arquivo do pacote")
    expect(copy).not_to include("Cole a URL da pasta do Drive")
    expect(copy).not_to include("URL da pasta do Drive")
  end

  def expect_archive_leitura(body, url: STANDING_ARCHIVE_URL)
    section = archive_section(body)
    expect(section.at_css('label[for="url"]').text.strip).to eq("URL da pasta do Google Drive")
    node = section.at_css("p#url")
    expect(node["class"]).to include("font-medium")
    expect(node.text.strip).to eq(url)
    expect(node["class"].to_s).not_to include("border-rule")
    expect(node["class"].to_s).not_to include("bg-sheet")
    expect(section.at_css("input, textarea, select")).to be_nil
    expect(section.text).not_to include("Salvar arquivo")
    expect(section.text).not_to include("Cole a URL da pasta do Google Drive")
    expect(section.at_css('input[type="submit"][value="Confirmar"]')).to be_nil
    expect(section.text).not_to include("Confirmar")
    expect(archive_edit_control(body).text.strip).to eq("Editar")
  end

  def expect_archive_edicao(body, url: STANDING_ARCHIVE_URL)
    form = archive_form(body)
    expect(form.at_css('input[type="submit"][value="Confirmar"]')).to be_present
    input = form.at_css("input#url")
    expect(input["class"]).to include("border-rule")
    expect(input["class"]).to include("bg-sheet")
    expect(input["readonly"]).to be_nil
    expect(input["disabled"]).to be_nil
    expect(input["value"]).to eq(url)
    expect(page_doc(body).at_css('label[for="url"]').text.strip).to eq("URL da pasta do Google Drive")
    section = archive_section(body)
    expect(archive_edit_control(body)).to be_nil
    expect(form.at_css('input[type="submit"][value="Salvar arquivo"]')).to be_nil
    expect(section.at_css("p#url")).to be_nil
  end

  def certificate_heading
    "Certificado Digital A1 - Para consulta na SEFAZ"
  end

  def certificate_empty_line
    "Não há certificado A1 instalado. Use Instalar certificado."
  end

  def certificate_section(body)
    page_doc(body).css("section").find { |section| section.at_css("h2")&.text&.strip == certificate_heading }
  end

  def certificate_install_details(body)
    certificate_section(body)&.at_css("#certificate")&.ancestors("details")&.first
  end

  def certificate_remover(body)
    certificate_section(body)&.css("input[type='submit'], button").find { |node| node["value"] == "Remover" || node.text.strip == "Remover" }
  end

  def expect_certificate_absent_copy(body)
    expect(body).to include(certificate_heading)
    expect(body).to include(certificate_empty_line)
    expect(body).not_to include("Certificado SEFAZ")
    expect(body).not_to include("Nenhum certificado")
    expect(body).not_to include("Válido até")
    expect(body).not_to include("Expirado em")
    expect(body).not_to include("Remover o certificado SEFAZ?")
    expect(body).not_to match(/\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}/)
  end

  def expect_certificate_install_fold(body, open:)
    details = certificate_install_details(body)
    expect(details).to be_present
    expect(details.has_attribute?("open")).to eq(open)
    expect(details.at_css("summary").text.strip).to eq("Instalar certificado")
    expect(details.at_css("#certificate")).to be_present
    expect(details.at_css("#passphrase")).to be_present
    form = details.at_css('form[action="/sefaz_certificate"]')
    expect(form.at_css('input[type="submit"][value="Instalar certificado"]')).to be_present
    expect(details.at_css("#certificate")["type"]).to eq("file")
  end

  def expect_certificate_listed_cnpj_row(body)
    expect(body).to include("11.222.333/0001-81")
    expect(body).to include("Válido até 18/09/2027")
    expect(certificate_remover(body)).to be_present
    expect(body).to include('data-turbo-confirm="Remover o certificado SEFAZ?"')
    expect(body).not_to include(certificate_empty_line)
    expect_certificate_install_fold(body, open: false)
    expect(certificate_remover(body).ancestors("details")).not_to include(certificate_install_details(body))
  end

  def bank_accounts_section(body)
    page_doc(body).css("section").find { |section| section.at_css("h2")&.text&.strip == "Contas bancárias" }
  end

  def bank_account_section_form(body)
    bank_accounts_section(body)&.css("form")&.find { |form| form.at_css("#name") && form.at_css("#compe") && form.at_css("#coordinates") }
  end

  def bank_account_row_edit_control(row_node)
    row_node.css("a, button").find { |node| node.text.strip == "Editar" }
  end

  def selected_compe(form)
    form.at_css('#compe option[selected]')&.[]("value")
  end

  def expect_bank_account_field_labels(form)
    expect(form.at_css('label[for="name"]').text.strip).to eq("Nome")
    expect(form.at_css('label[for="compe"]').text.strip).to eq("Banco")
    expect(form.at_css('label[for="coordinates"]').text.strip).to eq("Agência/Conta Corrente")
  end

  def expect_bank_account_add_form(body)
    form = bank_account_section_form(body)
    expect(form).to be_present
    expect(form["action"]).to eq("/bank_accounts")
    expect(form.at_css('input[name="_method"][value="patch"]')).to be_nil
    expect(form.at_css('input[type="submit"][value="Adicionar conta"]')).to be_present
    expect(form.at_css("#name")["value"].to_s).to eq("")
    expect(form.at_css("#coordinates")["value"].to_s).to eq("")
    expect(form.at_css("select#compe")).to be_present
    expect_bank_account_field_labels(form)
  end
end

RSpec.configure do |config|
  config.include PageHelpers
end
