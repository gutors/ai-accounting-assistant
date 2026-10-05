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

  def expect_accountant_labels(body)
    expect(page_doc(body).at_css('label[for="tax_id"]').text.strip).to eq("CPF/CNPJ (preencher apenas números)")
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
    expect_accountant_labels(body)
    expect(body).not_to include("Id fiscal")
    expect(body).not_to include("Destino do pacote")
    expect(accountant_edit_control(body)).to be_nil
  end

  def expect_accountant_leitura_cnpj_row(body)
    form = accountant_form(body)
    expect(form.at_css("#presentation_name")["value"]).to eq("Ana Contábil")
    expect(form.at_css("#tax_id")["value"]).to eq("11.222.333/0001-81")
    expect(form.at_css("#legal_name")["value"]).to eq("Contábil LTDA")
    expect(form.at_css("#pix_key")["value"]).to eq("chave-pix")
    expect(form.at_css("#destination_email")["value"]).to eq("ana@example.com")
    accountant_input_ids.each do |id|
      expect(form.at_css("##{id}")["readonly"]).to eq("readonly")
    end
    expect_accountant_labels(body)
    expect(form.at_css('input[type="submit"][value="Salvar contador"]')).to be_nil
    expect(body).not_to include("Cadastre o contador")
    expect(accountant_edit_control(body).text.strip).to eq("Editar")
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
end

RSpec.configure do |config|
  config.include PageHelpers
end
