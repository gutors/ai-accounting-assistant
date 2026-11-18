require "rails_helper"

RSpec.describe "Supporting documents", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  def signed_in
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    [ account, organization ]
  end

  def signed_submitter
    _coord, organization = plant_coordinator
    account, _ = plant_submitter(organization: organization)
    sign_in_as(account, organization: organization)
    [ account, organization ]
  end

  def recibo_params(photo: photo_jpg, **extra)
    { kind: "recibo", amount: "155,00", date: "2026-05-11", payee: "Padaria Central", photo: photo }.merge(extra)
  end

  def nota_params(**extra)
    { kind: "nota_fiscal", amount: "155,00", date: "2026-05-11", payee: "Padaria Central" }.merge(extra)
  end

  def nfe_chave
    "43260511222333000181550010000000011123456781"
  end

  def install_a1(organization)
    organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")
  end

  def stub_xml_consulta(chave = nfe_chave, **nfe)
    SefazConsulta.current.set(chave, SefazConsulta::Xml.new(authorized_nfe_xml(**nfe)))
  end

  def stub_resumo_consulta(chave = nfe_chave, amount_cents: 15500, payee: "Padaria Central", document_on: Date.new(2026, 5, 11))
    SefazConsulta.current.set(chave, SefazConsulta::Resumo.new(amount_cents:, payee:, document_on:))
  end

  def insert_form(body)
    page_doc(body).css("form").find { |node| node["action"] == "/supporting_documents" && node["method"] == "post" }
  end

  def selected_option_value(select)
    selected = select.at_css("option[selected]")
    (selected || select.at_css("option"))["value"]
  end

  def html_visible?(node)
    return false if node["hidden"]
    return false if node["class"].to_s.split.include?("hidden")

    node.ancestors.none? { |ancestor| ancestor["hidden"] || ancestor["class"].to_s.split.include?("hidden") }
  end

  def insert_section(body)
    page_doc(body).css("section").first
  end

  def identify_stream_doc(body)
    html = turbo_stream_nodes(body).map(&:inner_html).join
    Nokogiri::HTML(html)
  end

  def origin_copy(doc, field)
    doc.at_css(%([data-origin="#{field}"]))&.text&.strip
  end

  it "GET empty insert is file-first proof square" do
    signed_submitter

    get "/supporting_documents"

    expect(response).to have_http_status(:ok)
    section = insert_section(response.body)
    expect(section.at_css("h2").text.strip).to eq("Incluir documento")
    expect(section.at_css('label[for="photo"]')).to be_nil
    expect(section.at_css('label[for="xml"]')).to be_nil
    files = section.css('input[type="file"]')
    expect(files.size).to eq(1)
    expect(files.first["accept"]).to include("image/*")
    expect(files.first["accept"]).to include(".xml")
    expect(section.text).to include("Inclua o documento. Valor, data e favorecido saem do arquivo.")
    %w[amount date payee kind arquivo].each do |id|
      node = section.at_css("##{id}")
      expect(node).not_to be_nil
      expect(html_visible?(node)).to eq(false)
    end
    sem_mes = page_doc(response.body).css("section")[1]
    expect(sem_mes.at_css("h2").text.strip).to eq("Sem mês")
    expect(sem_mes.text).to include("Nenhum documento")
    form = insert_form(response.body)
    expect(form["class"]).to include("md:grid-cols-[minmax(0,1fr)_28rem]")
    children = form.element_children
    expect(children.first.name).to eq("aside")
    expect(children.last["class"]).to include("max-w-[28rem]")
    expect(children.first.text).to include("Solte a foto ou o XML, ou clique para escolher. Um arquivo só: foto ou XML.")
  end

  it "GET empty insert as submitter is file-first" do
    account, organization = plant_submitter
    sign_in_as(account, organization: organization)

    get "/supporting_documents"

    expect(response).to have_http_status(:ok)
    section = insert_section(response.body)
    expect(section.at_css('label[for="photo"]')).to be_nil
    expect(section.at_css('label[for="xml"]')).to be_nil
    expect(section.css('input[type="file"]').size).to eq(1)
    expect(section.text).to include("Inclua o documento. Valor, data e favorecido saem do arquivo.")
    expect(html_visible?(section.at_css("#amount"))).to eq(false)
  end

  it "POST identify authorized XML fills book without persisting" do
    signed_in

    post "/supporting_documents/identify", params: { file: authorized_xml("proc-nfe.xml") }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:ok)
    expect(turbo_stream_nodes(response.body).none? { |node|
      node["target"] == "file" || node["targets"].to_s.include?("#file")
    }).to eq(true)
    doc = identify_stream_doc(response.body)
    expect(doc.at_css("#arquivo")["value"]).to eq("XML")
    expect(selected_option_value(doc.at_css("select#kind"))).to eq("nota_fiscal")
    expect(doc.at_css("select#kind")["disabled"]).to be_present
    expect(doc.at_css("#amount")["value"]).to eq("155,00")
    expect(doc.at_css("#date")["value"]).to eq("2026-05-11")
    expect(doc.at_css("#payee")["value"]).to eq("Padaria Central")
    expect(doc.at_css("#chave")["value"]).to include("43260511222333000181550010000000011123456781")
    %w[amount date payee].each do |field|
      expect(origin_copy(doc, field)).to eq("XML autorizado")
      expect(doc.at_css("##{field}")["disabled"]).to be_present
    end
    expect(doc.text).to include("proc-nfe.xml")
    limpar = doc.css("button").find { |button| button.text.strip == "Limpar" }
    expect(limpar).not_to be_nil
    expect(limpar.ancestors.any? { |node| node["id"] == "identify-preview" }).to eq(true)
  end

  it "POST identify photo fields fills book unlocked" do
    signed_in
    stub_photo_fields("danfe.jpg")

    post "/supporting_documents/identify", params: { file: photo_jpg("danfe.jpg") }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:ok)
    doc = identify_stream_doc(response.body)
    expect(doc.at_css("#arquivo")["value"]).to eq("Foto")
    expect(selected_option_value(doc.at_css("select#kind"))).to eq("nota_fiscal")
    expect(doc.at_css("select#kind")["disabled"]).to be_present
    expect(doc.at_css("#amount")["value"]).to eq("155,00")
    expect(doc.at_css("#date")["value"]).to eq("2026-05-11")
    expect(doc.at_css("#payee")["value"]).to eq("Padaria Central")
    %w[amount date payee].each do |field|
      expect(origin_copy(doc, field)).to eq("Lido da foto")
      expect(doc.at_css("##{field}")["disabled"]).to be_nil
    end
    thumb = doc.at_css("#identify-preview img")
    expect(thumb).to be_present
    expect(thumb["alt"]).to eq("danfe.jpg")
  end

  it "POST identify pdf miss is recibo typed empty" do
    signed_in

    post "/supporting_documents/identify", params: { file: photo_with_ext("pdf") }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:ok)
    doc = identify_stream_doc(response.body)
    expect(doc.at_css("#arquivo")["value"]).to eq("Foto")
    expect(selected_option_value(doc.at_css("select#kind"))).to eq("recibo")
    expect(doc.at_css("select#kind")["disabled"]).to be_present
    expect(html_visible?(doc.at_css("#chave"))).to eq(false)
    expect(doc.at_css("#amount")["value"].to_s).to eq("")
    expect(doc.at_css("#date")["value"].to_s).to eq("")
    expect(doc.at_css("#payee")["value"].to_s).to eq("")
    %w[amount date payee].each do |field|
      expect(origin_copy(doc, field)).to eq("Digitado")
      expect(doc.at_css("##{field}")["disabled"]).to be_nil
    end
    expect(doc.at_css('input[type="submit"][value="Incluir documento"]')["disabled"]).to be_present
  end

  it "POST identify photo miss is recibo typed empty" do
    signed_in

    post "/supporting_documents/identify", params: { file: photo_jpg("empty.jpg") }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:ok)
    doc = identify_stream_doc(response.body)
    expect(doc.at_css("#arquivo")["value"]).to eq("Foto")
    expect(selected_option_value(doc.at_css("select#kind"))).to eq("recibo")
    expect(doc.at_css("select#kind")["disabled"]).to be_present
    expect(html_visible?(doc.at_css("#chave"))).to eq(false)
    expect(doc.at_css("#amount")["value"].to_s).to eq("")
    expect(doc.at_css("#date")["value"].to_s).to eq("")
    expect(doc.at_css("#payee")["value"].to_s).to eq("")
    %w[amount date payee].each do |field|
      expect(origin_copy(doc, field)).to eq("Digitado")
      expect(doc.at_css("##{field}")["disabled"]).to be_nil
    end
    expect(doc.at_css('input[type="submit"][value="Incluir documento"]')["disabled"]).to be_present
  end

  it "POST identify photo chave identified XML locks fields" do
    account, organization = signed_in
    install_a1(organization)
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    stub_xml_consulta

    post "/supporting_documents/identify", params: { file: photo_jpg("danfe.jpg") }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:ok)
    doc = identify_stream_doc(response.body)
    expect(selected_option_value(doc.at_css("select#kind"))).to eq("nota_fiscal")
    expect(doc.at_css("#amount")["value"]).to eq("155,00")
    expect(doc.at_css("#date")["value"]).to eq("2026-05-11")
    expect(doc.at_css("#payee")["value"]).to eq("Padaria Central")
    %w[amount date payee].each do |field|
      expect(origin_copy(doc, field)).to eq("XML autorizado")
      expect(doc.at_css("##{field}")["disabled"]).to be_present
    end
    expect(account).to eq(account)
  end

  it "POST identify photo chave when identified errors keeps chave and sefaz miss copy" do
    _account, organization = signed_in
    install_a1(organization)
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Error.new)

    post "/supporting_documents/identify", params: { file: photo_jpg("danfe.jpg") }, headers: turbo_stream_accept

    expect(response).to have_http_status(:ok)
    doc = identify_stream_doc(response.body)
    expect(doc.at_css("#chave")["value"]).to eq(nfe_chave)
    expect(doc.at_css("#amount")["value"]).to eq("")
    expect(doc.text).to include("A consulta SEFAZ não preencheu valor, data e favorecido. Informe-os.")
  end

  it "POST identify unreadable XML 422 keeps file input" do
    signed_in

    post "/supporting_documents/identify",
      params: { file: xml_file("nota.xml", "<nfe><") },
      headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    notice = turbo_stream_for(response.body, "[data-notice=error]")
    toast = turbo_stream_for(response.body, "toast-host")
    expect(notice.text).to include("O XML da nota fiscal não pôde ser lido")
    expect(toast.text).to include("O XML da nota fiscal não pôde ser lido")
    expect(turbo_stream_nodes(response.body).none? { |node|
      node["target"] == "file" || node["targets"].to_s.include?("form[action=\"/supporting_documents\"]")
    }).to eq(true)
  end

  it "unauthenticated POST identify 302 to login" do
    post "/supporting_documents/identify", params: { file: photo_jpg }

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "POST create authorized XML without kind persists nota_fiscal" do
    _account, organization = signed_in

    post "/supporting_documents", params: { xml: authorized_xml }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    doc = SupportingDocument.find_by!(organization: organization)
    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.fields_origin).to eq("uploaded_xml")
    expect(doc.xml).to be_attached
    expect(doc.photo).not_to be_attached
    expect(doc.amount_cents).to eq(15500)
  end

  it "POST create photo fields persists photo origin" do
    _account, organization = signed_in
    stub_photo_fields("danfe.jpg")

    post "/supporting_documents", params: {
      photo: photo_jpg("danfe.jpg"), amount: "155,00", date: "2026-05-11", payee: "Padaria Central"
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    doc = SupportingDocument.find_by!(organization: organization)
    expect(doc.photo).to be_attached
    expect(doc.xml).not_to be_attached
    expect(doc.fields_origin).to eq("photo")
  end

  it "POST create miss photo with typed values persists recibo" do
    _account, organization = signed_in

    post "/supporting_documents", params: {
      photo: photo_jpg("empty.jpg"), amount: "48,90", date: "2026-05-12", payee: "Papelaria Lume"
    }

    expect(response).to have_http_status(:found)
    doc = SupportingDocument.find_by!(organization: organization)
    expect(doc.kind).to eq("recibo")
    expect(doc.photo).to be_attached
    expect(doc.xml).not_to be_attached
    expect(doc.chave).to be_nil
    expect(doc.fields_origin).to eq("typed")
    expect(doc.amount_cents).to eq(4890)
  end

  it "POST create both photo and XML 422 xor" do
    signed_in

    post "/supporting_documents", params: nota_params(photo: photo_jpg, xml: authorized_xml)

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Envie a foto ou o XML")
  end

  it "POST create neither file 422 xor" do
    signed_in

    post "/supporting_documents", params: { amount: "155,00", date: "2026-05-11", payee: "Padaria Central" }

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Envie a foto ou o XML")
  end

  it "submitter identify then create XML is own account" do
    coord, organization = plant_coordinator
    other_org = create_organization!(name: "Outra")
    Access.create!(account: coord, organization: other_org, kind: :coordinator)
    sign_in_as(coord, organization: other_org)
    post "/supporting_documents", params: { xml: authorized_xml, payee: "Outra ONG" }
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    post "/supporting_documents/identify", params: { file: authorized_xml }, headers: turbo_stream_accept
    expect(response).to have_http_status(:ok)
    post "/supporting_documents", params: { xml: authorized_xml }

    doc = SupportingDocument.find_by!(organization: organization, payee: "Padaria Central")
    expect(doc.account_id).to eq(submitter.id)
    get "/supporting_documents"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Padaria Central")
    expect(response.body).not_to include("Outra ONG")
  end

  it "GET edit pdf photo embeds the blob in the proof square" do
    account, organization = signed_in
    document = SupportingDocument.insert(
      organization: organization, account: account, kind: "recibo",
      amount: "155,00", date: "2026-05-11", payee: "Padaria Central",
      photo: pdf_upload("nota.pdf", pngs_to_pdf(ocr_png("blank.png")))
    )

    get "/supporting_documents/#{document.id}/edit"

    expect(response).to have_http_status(:ok)
    page = page_doc(response.body)
    proof = page.at_css("[data-edit=proof]")
    embed = proof.at_css("embed[type='application/pdf']")
    expect(embed).to be_present
    expect(embed["src"]).to include("rails/active_storage")
    expect(proof.text).to include("Foto · nota.pdf")
    expect(proof.text).to include("O arquivo não pode ser alterado. Exclua o documento e inclua novamente.")
    expect(proof.at_css("p")&.text).not_to eq("nota.pdf")
  end

  it "POST create recibo pdf with raster chave persists typed recibo" do
    signed_in

    post "/supporting_documents", params: {
      kind: "recibo",
      file: pdf_upload("nota.pdf", pngs_to_pdf(code128_png)),
      amount: "155,00",
      date: "2026-05-11",
      payee: "Padaria Central"
    }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.count).to eq(1)
    document = SupportingDocument.last
    expect(document.kind).to eq("recibo")
    expect(document.chave).to be_nil
    expect(document.xml).not_to be_attached
    expect(document.photo).to be_attached
    expect(document.photo.filename.to_s).to eq("nota.pdf")
    expect(document.photo.content_type).to eq("application/pdf")
    expect(document.amount_cents).to eq(15500)
  end

  it "GET edit photo-only has Arquivo Foto and no xml picker" do
    account, organization = signed_in
    document = SupportingDocument.insert(
      organization: organization, account: account, kind: "nota_fiscal",
      amount: "155,00", date: "2026-05-11", payee: "Padaria Central", photo: photo_named("nota-padaria-central.jpg")
    )

    get "/supporting_documents/#{document.id}/edit"

    expect(response).to have_http_status(:ok)
    page = page_doc(response.body)
    expect(page.at_css('label[for="xml"]')).to be_nil
    expect(page.at_css("input#xml")).to be_nil
    arquivo = page.at_css("#arquivo")
    expect(html_visible?(arquivo)).to eq(true)
    expect(arquivo["value"]).to eq("Foto")
    expect(arquivo["disabled"]).to be_present
    expect(selected_option_value(page.at_css("select#kind"))).to eq("nota_fiscal")
    expect(page.at_css("select#kind")["disabled"]).to be_present
    proof = page.at_css("[data-edit=proof]")
    expect(proof.text).to include("Foto ·")
    expect(proof.text).to include("nota-padaria-central.jpg")
    expect(proof.text).to include("O arquivo não pode ser alterado. Exclua o documento e inclua novamente.")
    split = page.at_css("[data-edit=split]")
    expect(split["class"]).to include("md:grid-cols-[minmax(0,1fr)_28rem]")
    expect(split.element_children.first["data-edit"]).to eq("proof")
    expect(page.at_css("[data-edit=book]")["class"]).to include("max-w-[28rem]")
  end

  it "GET edit xml-only has Arquivo XML and no xml picker" do
    account, organization = signed_in
    document = SupportingDocument.insert(
      organization: organization, account: account, kind: "nota_fiscal",
      amount: "155,00", date: "2026-05-11", payee: "Padaria Central", photo: nil, xml: authorized_xml("nota-autorizada.xml")
    )

    get "/supporting_documents/#{document.id}/edit"

    page = page_doc(response.body)
    expect(page.at_css("#arquivo")["value"]).to eq("XML")
    expect(page.at_css("input#xml")).to be_nil
    expect(page.at_css("[data-edit=proof]").text).to include("nota-autorizada.xml")
  end

  it "PATCH xml onto photo-only 422 XML_LOCKED" do
    signed_in
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    document = SupportingDocument.last
    expect(document.xml).not_to be_attached

    patch "/supporting_documents/#{document.id}", params: { xml: authorized_xml }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq(SupportingDocument::XML_LOCKED)
    expect(document.reload.xml).not_to be_attached
  end

  it "GET edit legacy both blobs Arquivo XML no picker PATCH keeps blobs" do
    account, organization = signed_in
    document = SupportingDocument.insert(
      organization: organization, account: account, kind: "nota_fiscal",
      amount: "155,00", date: "2026-05-11", payee: "Padaria Central", photo: photo_jpg("danfe.jpg"), xml: nil
    )
    document.xml.attach(io: StringIO.new(authorized_nfe_xml), filename: "legado.xml", content_type: "application/xml")

    get "/supporting_documents/#{document.id}/edit"

    page = page_doc(response.body)
    expect(page.at_css("#arquivo")["value"]).to eq("XML")
    expect(page.at_css("input#xml")).to be_nil
    expect(page.at_css("[data-edit=proof]").text).to include("danfe.jpg")

    patch "/supporting_documents/#{document.id}", params: { observation: "ok" }

    expect(response).to have_http_status(:found)
    document.reload
    expect(document.photo).to be_attached
    expect(document.xml).to be_attached
  end

  it "GET edit uploaded_xml origins XML autorizado locked" do
    account, organization = signed_in
    document = SupportingDocument.insert(
      organization: organization, account: account, kind: "nota_fiscal",
      amount: "155,00", date: "2026-05-11", payee: "Padaria Central", photo: nil, xml: authorized_xml
    )

    get "/supporting_documents/#{document.id}/edit"

    page = page_doc(response.body)
    %w[amount date payee].each do |field|
      expect(page.at_css("##{field}")["disabled"]).to be_present
      expect(origin_copy(page, field)).to eq("XML autorizado")
    end
  end

  it "GET edit identified origins XML autorizado locked" do
    account, organization = signed_in
    install_a1(organization)
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    stub_xml_consulta
    document = SupportingDocument.insert(
      organization: organization, account: account, kind: "nota_fiscal",
      amount: nil, date: nil, payee: nil, photo: photo_jpg("danfe.jpg"), xml: nil
    )
    expect(document.fields_origin).to eq("identified")

    get "/supporting_documents/#{document.id}/edit"

    page = page_doc(response.body)
    %w[amount date payee].each do |field|
      expect(page.at_css("##{field}")["disabled"]).to be_present
      expect(origin_copy(page, field)).to eq("XML autorizado")
    end
  end

  it "GET edit photo origins Lido da foto unlocked" do
    account, organization = signed_in
    stub_photo_fields("danfe.jpg")
    document = SupportingDocument.insert(
      organization: organization, account: account, kind: "nota_fiscal",
      amount: nil, date: nil, payee: nil, photo: photo_jpg("danfe.jpg"), xml: nil
    )
    expect(document.fields_origin).to eq("photo")

    get "/supporting_documents/#{document.id}/edit"

    page = page_doc(response.body)
    %w[amount date payee].each do |field|
      expect(page.at_css("##{field}")["disabled"]).to be_nil
      expect(origin_copy(page, field)).to eq("Lido da foto")
    end
  end

  it "POST identify authorized NFCom XML fills book without persisting" do
    signed_in

    post "/supporting_documents/identify", params: { file: nfcom_file }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:ok)
    doc = identify_stream_doc(response.body)
    expect(selected_option_value(doc.at_css("select#kind"))).to eq("nota_fiscal")
    expect(doc.at_css("select#kind")["disabled"]).to be_present
    expect(doc.at_css("#amount")["value"]).to eq("256,80")
    expect(doc.at_css("#date")["value"]).to eq("2026-06-15")
    expect(doc.at_css("#payee")["value"]).to eq("EMPRESA TELECOM EXEMPLO S.A.")
    expect(doc.at_css("#chave")["value"]).to include("27260611222333000181620010008920781028142810")
    %w[amount date payee].each do |field|
      expect(origin_copy(doc, field)).to eq("XML autorizado")
      expect(doc.at_css("##{field}")["disabled"]).to be_present
    end
  end

  it "POST create NFCom XML without kind persists 25680 uploaded_xml" do
    _account, organization = signed_in

    post "/supporting_documents", params: { file: nfcom_file }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    doc = SupportingDocument.find_by!(organization: organization)
    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.amount_cents).to eq(25680)
    expect(doc.document_on).to eq(Date.new(2026, 6, 15))
    expect(doc.payee).to eq("EMPRESA TELECOM EXEMPLO S.A.")
    expect(doc.chave).to eq("27260611222333000181620010008920781028142810")
    expect(doc.fields_origin).to eq("uploaded_xml")
    expect(doc.xml).to be_attached
    expect(doc.photo).not_to be_attached
  end

  it "POST identify authorized NF3e XML fills book without persisting" do
    signed_in

    post "/supporting_documents/identify", params: { file: nf3e_file }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:ok)
    doc = identify_stream_doc(response.body)
    expect(doc.at_css("#amount")["value"]).to eq("189,40")
    expect(doc.at_css("#date")["value"]).to eq("2026-05-20")
    expect(doc.at_css("#payee")["value"]).to eq("Companhia Energetica Exemplo")
    expect(doc.at_css("#chave")["value"]).to include("27260611222333000181660010000008920781028142")
    expect(origin_copy(doc, "amount")).to eq("XML autorizado")
  end

  it "POST create NF3e XML without kind persists 18940 uploaded_xml" do
    _account, organization = signed_in

    post "/supporting_documents", params: { file: nf3e_file }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    doc = SupportingDocument.find_by!(organization: organization)
    expect(doc.amount_cents).to eq(18940)
    expect(doc.document_on).to eq(Date.new(2026, 5, 20))
    expect(doc.payee).to eq("Companhia Energetica Exemplo")
    expect(doc.chave).to eq("27260611222333000181660010000008920781028142")
    expect(doc.fields_origin).to eq("uploaded_xml")
  end

  it "POST identify authorized national NFSe XML fills book without persisting" do
    signed_in

    post "/supporting_documents/identify", params: { file: nfse_file }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:ok)
    doc = identify_stream_doc(response.body)
    expect(doc.at_css("#amount")["value"]).to eq("610,00")
    expect(doc.at_css("#date")["value"]).to eq("2026-05-06")
    expect(doc.at_css("#payee")["value"]).to eq("Contabilidade Exemplo Ltda")
    expect(doc.at_css("#chave")["value"]).to include("41260511222333000181000000000000000000000000000001")
    expect(origin_copy(doc, "amount")).to eq("XML autorizado")
  end

  it "POST create national NFSe XML without kind persists 61000 uploaded_xml" do
    _account, organization = signed_in

    post "/supporting_documents", params: { file: nfse_file }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    doc = SupportingDocument.find_by!(organization: organization)
    expect(doc.amount_cents).to eq(61000)
    expect(doc.document_on).to eq(Date.new(2026, 5, 6))
    expect(doc.payee).to eq("Contabilidade Exemplo Ltda")
    expect(doc.chave).to eq("41260511222333000181000000000000000000000000000001")
    expect(doc.fields_origin).to eq("uploaded_xml")
  end

  it "submitter identify then create NFCom is own account and scoped list" do
    coord, organization = plant_coordinator
    other_org = create_organization!(name: "Outra")
    Access.create!(account: coord, organization: other_org, kind: :coordinator)
    sign_in_as(coord, organization: other_org)
    post "/supporting_documents", params: { file: authorized_xml, payee: "Outra ONG" }
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    post "/supporting_documents/identify", params: { file: nfcom_file }, headers: turbo_stream_accept
    expect(response).to have_http_status(:ok)
    post "/supporting_documents", params: { file: nfcom_file }

    doc = SupportingDocument.find_by!(organization: organization, payee: "EMPRESA TELECOM EXEMPLO S.A.")
    expect(doc.account_id).to eq(submitter.id)
    get "/supporting_documents"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("EMPRESA TELECOM EXEMPLO S.A.")
    expect(response.body).not_to include("Outra ONG")
  end

  it "GET edit NFCom uploaded_xml origins XML autorizado locked" do
    account, organization = signed_in
    document = SupportingDocument.insert(
      organization: organization, account: account, kind: "",
      amount: nil, date: nil, payee: nil, photo: nil, xml: nfcom_file
    )

    get "/supporting_documents/#{document.id}/edit"

    page = page_doc(response.body)
    %w[amount date payee].each do |field|
      expect(page.at_css("##{field}")["disabled"]).to be_present
      expect(origin_copy(page, field)).to eq("XML autorizado")
    end
  end

  it "PATCH payee on NFCom uploaded XML 422 LOCKED_FIELDS" do
    account, organization = signed_in
    document = SupportingDocument.insert(
      organization: organization, account: account, kind: "",
      amount: nil, date: nil, payee: nil, photo: nil, xml: nfcom_file
    )

    patch "/supporting_documents/#{document.id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Valor, data e favorecido vêm da nota e não podem ser alterados")
    expect(SupportingDocument.find(document.id).payee).to eq("EMPRESA TELECOM EXEMPLO S.A.")
  end

  it "POST identify infNFe without vNF 422 unreadable" do
    signed_in
    xml = xml_file("sem-vnf.xml", <<~XML)
      <?xml version="1.0" encoding="UTF-8"?>
      <nfeProc xmlns="http://www.portalfiscal.inf.br/nfe">
        <NFe>
          <infNFe Id="NFe43260511222333000181550010000000011123456781">
            <ide><dhEmi>2026-05-11T10:00:00-03:00</dhEmi></ide>
            <emit><xNome>Padaria Central</xNome></emit>
          </infNFe>
        </NFe>
      </nfeProc>
    XML

    post "/supporting_documents/identify", params: { file: xml }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    notice = turbo_stream_for(response.body, "[data-notice=error]")
    toast = turbo_stream_for(response.body, "toast-host")
    expect(notice.text).to include("O XML da nota fiscal não pôde ser lido")
    expect(toast.text).to include("O XML da nota fiscal não pôde ser lido")
  end

  it "POST identify CTe XML 422 unsupported copy" do
    signed_in

    post "/supporting_documents/identify", params: { file: cte_file }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    notice = turbo_stream_for(response.body, "[data-notice=error]")
    toast = turbo_stream_for(response.body, "toast-host")
    expect(notice.text).to include("Este XML não é NF-e, NFC-e, NFS-e nacional, NFCom ou NF3e")
    expect(toast.text).to include("Este XML não é NF-e, NFC-e, NFS-e nacional, NFCom ou NF3e")
  end

  it "POST identify municipal NFSe XML 422 unsupported copy" do
    signed_in

    post "/supporting_documents/identify", params: { file: municipal_nfse_file }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    notice = turbo_stream_for(response.body, "[data-notice=error]")
    toast = turbo_stream_for(response.body, "toast-host")
    expect(notice.text).to include("Este XML não é NF-e, NFC-e, NFS-e nacional, NFCom ou NF3e")
    expect(toast.text).to include("Este XML não é NF-e, NFC-e, NFS-e nacional, NFCom ou NF3e")
  end

  it "POST create CTe XML 422 unsupported copy" do
    signed_in

    post "/supporting_documents", params: { file: cte_file }

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Este XML não é NF-e, NFC-e, NFS-e nacional, NFCom ou NF3e")
  end

  def lote_chave(index)
    "4326051122233300018155001000000001112345#{(6780 + index).to_s.rjust(4, "0")}"
  end

  def batch_xml_item(name, payee:, index:, vnf: "155.00", date: "2026-05-11", amount: "155,00")
    {
      file: authorized_xml(name, vnf: vnf, emit: payee, dhemi: "#{date}T10:00:00-03:00", chave: lote_chave(index)),
      amount: amount,
      date: date,
      payee: payee
    }
  end

  def twelve_ready_payees
    [
      "Padaria Central", "Mercado Bom Preço", "Farmácia São José", "Atacado Verde",
      "Gráfica Norte", "Hortifruti da Praça", "Transportes Litoral", "Copiadora Central",
      "Café do Ponto", "Oficina do Bairro", "Livraria Escolar", "Papelaria Lume"
    ]
  end

  it "GET coordinator empty insert is lote drop" do
    signed_in

    get "/supporting_documents"

    expect(response).to have_http_status(:ok)
    section = insert_section(response.body)
    expect(section.at_css("h2").text.strip).to eq("Incluir documentos")
    files = section.css('input[type="file"]')
    expect(files.size).to eq(1)
    expect(files.first["multiple"]).to be_present
    expect(files.first["accept"]).to include("image/*")
    expect(files.first["accept"]).to include(".xml")
    expect(section.text).not_to include("Situação")
    expect(section.text).not_to include("Incluir prontos")
    sem_mes = page_doc(response.body).css("section")[1]
    expect(sem_mes.at_css("h2").text.strip).to eq("Sem mês")
    expect(sem_mes.text).to include("Nenhum documento")
  end

  it "GET submitter empty insert stays one-file square" do
    signed_submitter

    get "/supporting_documents"

    section = insert_section(response.body)
    expect(section.at_css("h2").text.strip).to eq("Incluir documento")
    file = section.at_css('input[type="file"]')
    expect(file["multiple"]).to be_nil
    expect(section.text).to include("Inclua o documento. Valor, data e favorecido saem do arquivo.")
    expect(section.text).not_to include("Incluir prontos")
  end

  it "POST batch XML with chave persists" do
    signed_in

    post "/supporting_documents/batch", params: {
      documents: [ batch_xml_item("proc-nfe-padaria.xml", payee: "Padaria Central", index: 0).merge(kind: "nota_fiscal", chave: lote_chave(0)) ]
    }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.last.chave).to eq(lote_chave(0))
  end

  it "POST batch two authorized XMLs persists both" do
    signed_in

    post "/supporting_documents/batch", params: {
      documents: [
        batch_xml_item("proc-nfe-padaria.xml", payee: "Padaria Central", index: 0, vnf: "155.00", amount: "155,00"),
        batch_xml_item("proc-nfe-farmacia.xml", payee: "Farmácia São José", index: 1, vnf: "89.40", date: "2026-05-03", amount: "89,40")
      ]
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    expect(SupportingDocument.count).to eq(2)
    get "/supporting_documents"
    list = response.body[response.body.index("Sem mês")..]
    expect(list).to include("Padaria Central", "Farmácia São José", "R$ 155,00", "R$ 89,40")
  end

  it "POST batch twelve ready omits Digitar and Erro files" do
    signed_in
    documents = twelve_ready_payees.each_with_index.map do |payee, index|
      batch_xml_item("proc-#{index}.xml", payee: payee, index: index)
    end

    post "/supporting_documents/batch", params: { documents: documents }

    expect(SupportingDocument.count).to eq(12)
    get "/supporting_documents"
    list = response.body[response.body.index("Sem mês")..]
    twelve_ready_payees.each { |payee| expect(list).to include(payee) }
    expect(list).not_to include("empty.jpg")
  end

  it "POST batch missing amount 422 names filename" do
    signed_in

    post "/supporting_documents/batch", params: {
      documents: [
        batch_xml_item("proc-nfe-padaria.xml", payee: "Padaria Central", index: 0),
        batch_xml_item("proc-nfe-farmacia.xml", payee: "Farmácia São José", index: 1).merge(amount: "")
      ]
    }

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    notice = error_notice_text(response.body)
    expect(notice).to include("proc-nfe-farmacia.xml")
    expect(notice).to include("Faltam valor, data ou favorecido.")
  end

  it "submitter POST batch persists none and 404" do
    signed_submitter

    post "/supporting_documents/batch", params: {
      documents: [ batch_xml_item("proc-nfe-padaria.xml", payee: "Padaria Central", index: 0) ]
    }

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:not_found)
  end

  it "unauthenticated POST batch 302 to login" do
    post "/supporting_documents/batch", params: {
      documents: [ batch_xml_item("proc-nfe-padaria.xml", payee: "Padaria Central", index: 0) ]
    }

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "submitter POST XML one-file persists 302" do
    account, organization = signed_submitter

    post "/supporting_documents", params: { file: authorized_xml("proc-nfe.xml") }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    doc = SupportingDocument.find_by!(organization: organization)
    expect(doc.account).to eq(account)
    expect(doc.xml).to be_attached
  end

  def batch_danfe_item
    {
      file: photo_jpg("danfe.jpg"),
      kind: "nota_fiscal",
      chave: nfe_chave,
      amount: "155,00",
      date: "2026-05-11",
      payee: "Padaria Central"
    }
  end

  it "POST batch JPEG with chave persists without photo extract" do
    signed_in
    expect(PhotoSymbols.current).not_to receive(:scan)
    expect(PhotoOcr).not_to receive(:text)
    expect(PublicNfceConsulta.current).not_to receive(:fetch)
    expect(PhotoFields.current).not_to receive(:read)

    post "/supporting_documents/batch", params: { documents: [ batch_danfe_item ] }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.count).to eq(1)
    doc = SupportingDocument.last
    expect(doc.chave).to eq(nfe_chave)
    expect(doc.amount_cents).to eq(15500)
  end

  it "POST batch JPEG with chave consulta attaches XML" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta

    post "/supporting_documents/batch", params: { documents: [ batch_danfe_item ] }

    expect(response).to have_http_status(:found)
    doc = SupportingDocument.last
    expect(doc.xml).to be_attached
    expect(doc.amount_cents).to eq(15500)
    expect(doc.payee).to eq("Padaria Central")
  end

  it "POST batch recibo without chave persists chave nil" do
    signed_in

    post "/supporting_documents/batch", params: {
      documents: [ {
        file: photo_jpg("empty.jpg"),
        kind: "recibo",
        amount: "10,00",
        date: "2026-05-10",
        payee: "Mercado Bom Preço"
      } ]
    }

    expect(response).to have_http_status(:found)
    doc = SupportingDocument.last
    expect(doc.kind).to eq("recibo")
    expect(doc.chave).to be_nil
    expect(doc.payee).to eq("Mercado Bom Preço")
  end

  it "POST batch photo and XML on one item 422 xor" do
    signed_in

    post "/supporting_documents/batch", params: {
      documents: [ {
        photo: photo_jpg,
        xml: authorized_xml,
        amount: "155,00",
        date: "2026-05-11",
        payee: "Padaria Central"
      } ]
    }

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Envie a foto ou o XML")
  end

  it "GET edit typed origins Digitado" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents/#{document.id}/edit"

    page = page_doc(response.body)
    %w[amount date payee].each do |field|
      expect(origin_copy(page, field)).to eq("Digitado")
    end
  end
end
