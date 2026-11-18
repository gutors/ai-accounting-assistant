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

  def editar_link(document_row)
    document_row.css("a").find { |node| node.text.strip == "Editar" }
  end

  it "submitter PATCH unmatched-in-package Padaria returns 422 Documento ja pertence a um mes" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    document = plant_recibo(organization, submitter, payee: "Padaria Central", amount: "155,00")
    sign_in_as(coord, organization: organization)
    ready_to_close!(organization)
    plant_month(organization)
    post "/months/2026-05/close", params: { supporting_document_ids: [ document.id ] }
    sign_in_as(submitter, organization: organization)

    patch "/supporting_documents/#{document.id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Documento já pertence a um mês")
    expect(document.reload.payee).to eq("Padaria Central")
  end

  it "submitter DELETE unmatched-in-package Padaria returns 422 Documento ja pertence a um mes" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    document = plant_recibo(organization, submitter, payee: "Padaria Central", amount: "155,00")
    sign_in_as(coord, organization: organization)
    ready_to_close!(organization)
    plant_month(organization)
    post "/months/2026-05/close", params: { supporting_document_ids: [ document.id ] }
    sign_in_as(submitter, organization: organization)

    delete "/supporting_documents/#{document.id}"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Documento já pertence a um mês")
    expect(SupportingDocument.find(document.id)).to be_persisted
    expect(document.reload.month_id).to be_present
  end

  it "POST photo chave with consulta XML fills fields and redirects" do
    _account, organization = signed_in
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    install_a1(organization)
    stub_xml_consulta

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("danfe.jpg") }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    doc = SupportingDocument.last
    expect(doc.amount_cents).to eq(15500)
    expect(doc.document_on).to eq(Date.new(2026, 5, 11))
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.chave).to eq(nfe_chave)
    expect(doc.xml).to be_attached
    get "/supporting_documents"
    expect(response.body).to include("R$ 155,00")
    expect(response.body).to include("11/05/2026")
    expect(response.body).to include("Padaria Central")
    expect(response.body).to include(nfe_chave)
  end

  it "submitter POST photo chave with consulta XML persists and omits certificate" do
    coord, organization = plant_coordinator
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    install_a1(organization)
    stub_xml_consulta
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("danfe.jpg") }

    expect(SupportingDocument.last.amount_cents).to eq(15500)
    expect(SupportingDocument.last.xml).to be_attached
    get "/supporting_documents"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("R$ 155,00")
    expect(response.body).not_to include("11.222.333/0001-81")
    expect(response.body).not_to include("Válido até")
    expect(response.body).not_to include("passphrase-secreta")
    expect(coord).to be_present
  end

  it "POST pdf photo chave with consulta XML redirects" do
    _account, organization = signed_in
    stub_photo_symbols("foto.pdf", chave: nfe_chave)
    install_a1(organization)
    stub_xml_consulta

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_with_ext("pdf") }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.last.chave).to eq(nfe_chave)
    expect(SupportingDocument.last.xml).to be_attached
  end

  it "POST printed-digit chave with consulta XML persists chave" do
    _account, organization = signed_in
    stub_photo_symbols("printed.jpg", chave: nfe_chave)
    install_a1(organization)
    stub_xml_consulta

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("printed.jpg") }

    expect(SupportingDocument.last.chave).to eq(nfe_chave)
    expect(SupportingDocument.last.amount_cents).to eq(15500)
    expect(SupportingDocument.last.xml).to be_attached
  end

  it "POST photo chave wins over typed chave" do
    _account, organization = signed_in
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    install_a1(organization)
    stub_xml_consulta
    stub_xml_consulta(other_chave, vnf: "100.00")

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("danfe.jpg"), chave: other_chave }

    expect(SupportingDocument.last.chave).to eq(nfe_chave)
    expect(SupportingDocument.last.amount_cents).to eq(15500)
  end

  it "POST non-44 photo decode falls through to typed chave" do
    _account, organization = signed_in
    stub_photo_symbols("bad.jpg", chave: "123")
    install_a1(organization)
    stub_xml_consulta

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("bad.jpg"), chave: nfe_chave }

    expect(SupportingDocument.last.chave).to eq(nfe_chave)
    expect(SupportingDocument.last.xml).to be_attached
  end

  it "POST recibo ignores photo chave and PATCH payee redirects" do
    signed_in
    stub_photo_symbols("recibo.jpg", chave: nfe_chave)
    post "/supporting_documents", params: recibo_params
    id = SupportingDocument.last.id

    expect(SupportingDocument.find(id).kind).to eq("recibo")
    expect(SupportingDocument.find(id).chave).to be_nil
    expect(SupportingDocument.find(id).xml).not_to be_attached
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }
    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
  end

  it "POST uploaded XML chave wins over photo chave" do
    signed_in
    stub_photo_symbols("danfe.jpg", chave: other_chave)

    post "/supporting_documents", params: { kind: "nota_fiscal", xml: authorized_xml }

    expect(SupportingDocument.last.amount_cents).to eq(15500)
    expect(SupportingDocument.last.chave).to eq(nfe_chave)
  end

  it "POST photo chave without certificate stays correctable" do
    signed_in
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    post "/supporting_documents", params: nota_params(photo: photo_jpg("danfe.jpg"))
    id = SupportingDocument.last.id

    expect(SupportingDocument.find(id).chave).to eq(nfe_chave)
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }
    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
  end

  it "POST photo chave when consulta errors stays typed" do
    _account, organization = signed_in
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    install_a1(organization)
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Error.new)
    post "/supporting_documents", params: nota_params(photo: photo_jpg("danfe.jpg"))
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
  end

  it "POST photo chave with resumo locks fields without xml" do
    _account, organization = signed_in
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    install_a1(organization)
    stub_resumo_consulta

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("danfe.jpg") }

    doc = SupportingDocument.last
    expect(doc.amount_cents).to eq(15500)
    expect(doc.photo).to be_attached
    expect(doc.xml).not_to be_attached
    patch "/supporting_documents/#{doc.id}", params: { amount: "200,00" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Valor, data e favorecido vêm da nota e não podem ser alterados")
  end

  it "POST NFC-e QR public consulta fills fields and PATCH amount redirects" do
    signed_in
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("nfce.jpg") }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    doc = SupportingDocument.last
    expect(doc.amount_cents).to eq(15500)
    expect(doc.document_on).to eq(Date.new(2026, 5, 11))
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.chave).to eq(nfce_chave)
    expect(doc.xml).not_to be_attached
    get "/supporting_documents"
    expect(response.body).to include("R$ 155,00")
    expect(response.body).to include("11/05/2026")
    expect(response.body).to include("Padaria Central")
    get "/supporting_documents/#{doc.id}/edit"
    expect(page_doc(response.body).at_css("#chave")["value"]).to eq(nfce_chave)
    patch "/supporting_documents/#{doc.id}", params: { amount: "200,00" }
    expect(response).to have_http_status(:found)
    expect(doc.reload.amount_cents).to eq(20000)
  end

  it "POST NFC-e QR public consulta with blank wrap key PATCH amount redirects" do
    _account, organization = signed_in
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    install_a1(organization)
    stub_xml_consulta(nfce_chave, vnf: "100.00")
    with_env("SEFAZ_WRAP_KEY" => nil) do
      post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("nfce.jpg") }
    end
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { amount: "200,00" }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).amount_cents).to eq(20000)
  end

  it "POST NFC-e QR public consulta with expired certificate PATCH amount redirects" do
    _account, organization = signed_in
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    travel_to Date.new(2026, 5, 11) do
      organization.install_sefaz_certificate(
        file: sefaz_pfx(not_after: Date.new(2026, 5, 11), name: "exp.pfx"),
        passphrase: "passphrase-secreta"
      )
    end
    travel_to Date.new(2026, 5, 12) do
      stub_xml_consulta(nfce_chave, vnf: "100.00")
      post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("nfce.jpg") }
      id = SupportingDocument.last.id
      patch "/supporting_documents/#{id}", params: { amount: "200,00" }
      expect(response).to have_http_status(:found)
      expect(SupportingDocument.find(id).amount_cents).to eq(20000)
    end
  end

  it "POST NFC-e QR public consulta when identified errors PATCH amount redirects" do
    _account, organization = signed_in
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    install_a1(organization)
    SefazConsulta.current.set(nfce_chave, SefazConsulta::Error.new)
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("nfce.jpg") }
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { amount: "200,00" }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).amount_cents).to eq(20000)
  end

  it "POST NFC-e QR public consulta when identified not found PATCH amount redirects" do
    _account, organization = signed_in
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    install_a1(organization)
    [ SefazConsulta::NotFound.new, SefazConsulta::WindowExpired.new ].each do |result|
      SefazConsulta.reset!
      PhotoSymbols.reset!
      PhotoFields.reset!
      PublicNfceConsulta.reset!
      stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
      stub_public_fields(nfce_qr_url)
      SefazConsulta.current.set(nfce_chave, result)
      post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("nfce.jpg") }
      id = SupportingDocument.last.id
      patch "/supporting_documents/#{id}", params: { amount: "200,00" }
      expect(response).to have_http_status(:found)
      expect(SupportingDocument.find(id).amount_cents).to eq(20000)
    end
  end

  it "POST NFC-e QR identified XML wins over public consulta" do
    _account, organization = signed_in
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url, amount_cents: 20000, payee: "Mercado Silva")
    install_a1(organization)
    stub_xml_consulta(nfce_chave)

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("nfce.jpg") }

    doc = SupportingDocument.last
    expect(doc.amount_cents).to eq(15500)
    expect(doc.xml).to be_attached
    patch "/supporting_documents/#{doc.id}", params: { amount: "200,00" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Valor, data e favorecido vêm da nota e não podem ser alterados")
  end

  it "POST CODE-128 without QR URL does not call public consulta" do
    signed_in
    stub_photo_symbols("code128.jpg", chave: nfe_chave)
    stub_public_fields("https://www.sefaz.rs.gov.br/anywhere", payee: "Mercado Silva")

    post "/supporting_documents", params: nota_params(photo: photo_jpg("code128.jpg"))

    expect(SupportingDocument.last.payee).to eq("Padaria Central")
  end

  it "POST QR 127.0.0.1 does not fetch and keeps typed payee" do
    signed_in
    stub_photo_symbols("ssrf.jpg", chave: nfe_chave, qr_url: "http://127.0.0.1/nfce")

    post "/supporting_documents", params: nota_params(photo: photo_jpg("ssrf.jpg"))

    expect(SupportingDocument.last.payee).to eq("Padaria Central")
    expect(SupportingDocument.last.xml).not_to be_attached
  end

  it "POST QR example.com does not fetch and keeps typed payee" do
    signed_in
    stub_photo_symbols("ex.jpg", chave: nfe_chave, qr_url: "https://example.com/nfce")

    post "/supporting_documents", params: nota_params(photo: photo_jpg("ex.jpg"))

    expect(SupportingDocument.last.payee).to eq("Padaria Central")
    expect(SupportingDocument.last.xml).not_to be_attached
  end

  it "POST NFC-e QR when public consulta errors keeps typed payee" do
    signed_in
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    PublicNfceConsulta.current.set(nfce_qr_url, PublicNfceConsulta::Error.new)

    post "/supporting_documents", params: nota_params(photo: photo_jpg("nfce.jpg"))

    expect(SupportingDocument.last.payee).to eq("Padaria Central")
  end

  it "POST NFC-e QR public partial three keeps typed payee" do
    signed_in
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    PublicNfceConsulta.current.set(
      nfce_qr_url,
      PublicNfceConsulta::Fields.new(amount_cents: 15500, payee: nil, document_on: nil)
    )

    post "/supporting_documents", params: nota_params(photo: photo_jpg("nfce.jpg"))

    expect(SupportingDocument.last.payee).to eq("Padaria Central")
  end

  it "POST NFC-e QR public consulta payee is emitente not destinatario" do
    signed_in
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("nfce.jpg") }

    expect(SupportingDocument.last.payee).to eq("Padaria Central")
    expect(SupportingDocument.last.payee).not_to include("ONG Destinataria")
  end

  it "POST photo field reading fills emitente and PATCH payee redirects" do
    signed_in
    stub_photo_fields("fields.jpg")

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("fields.jpg") }

    expect(response).to have_http_status(:found)
    get "/supporting_documents"
    expect(response.body).to include("R$ 155,00")
    expect(response.body).to include("Padaria Central")
    expect(response.body).not_to include("ONG Destinataria")
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }
    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
  end

  it "POST CODE-128 when identified errors uses field reading" do
    _account, organization = signed_in
    stub_photo_symbols("code128.jpg", chave: nfe_chave)
    stub_photo_fields("code128.jpg")
    install_a1(organization)
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Error.new)
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("code128.jpg") }
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
  end

  it "POST NFC-e QR when public errors uses field reading" do
    signed_in
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    PublicNfceConsulta.current.set(nfce_qr_url, PublicNfceConsulta::Error.new)
    stub_photo_fields("nfce.jpg")
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("nfce.jpg") }
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
  end

  it "POST photo field reading partial three uses typed amount" do
    signed_in
    PhotoFields.current.set("partial.jpg", amount_cents: 15500, document_on: nil, payee: nil)

    post "/supporting_documents", params: nota_params(photo: photo_jpg("partial.jpg"), amount: "100,00")

    expect(SupportingDocument.last.amount_cents).to eq(10000)
    expect(SupportingDocument.last.payee).to eq("Padaria Central")
  end

  it "POST nota photo with all extracts missing returns 422" do
    _account, organization = signed_in

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("empty.jpg") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Informe valor, data e favorecido")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "POST recibo ignores photo field reading" do
    signed_in
    stub_photo_fields("recibo.jpg", payee: "Mercado Silva")

    post "/supporting_documents", params: recibo_params

    expect(SupportingDocument.last.payee).to eq("Padaria Central")
  end

  it "POST photo field reading wins over typed payee" do
    signed_in
    stub_photo_fields("fields.jpg")

    post "/supporting_documents", params: nota_params(photo: photo_jpg("fields.jpg"), payee: "Mercado Silva")

    expect(SupportingDocument.last.payee).to eq("Padaria Central")
  end

  it "POST unreadable XML does not fall through to photo field reading" do
    _account, organization = signed_in
    stub_photo_fields("danfe.jpg")

    post "/supporting_documents", params: {
      kind: "nota_fiscal", xml: xml_file("nota.xml", "<nfe><")
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("O XML da nota fiscal não pôde ser lido")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "PATCH chave on photo-filled nota keeps 15500 and includes Usar dados da SEFAZ" do
    _account, organization = signed_in
    stub_photo_fields("fields.jpg")
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("fields.jpg") }
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
    get "/supporting_documents/#{id}/edit"
    expect(response.body).to include("Usar dados da SEFAZ")
  end

  it "confirm identified SEFAZ on photo-filled nota persists 10000" do
    _account, organization = signed_in
    stub_photo_fields("fields.jpg")
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("fields.jpg") }
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }

    post "/supporting_documents/#{id}/sefaz_confirm"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    get "/supporting_documents"
    expect(response.body).to include("R$ 100,00")
    expect(response.body).not_to include("R$ 155,00")
    patch "/supporting_documents/#{id}", params: { amount: "200,00" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Valor, data e favorecido vêm da nota e não podem ser alterados")
  end

  it "PATCH chave on public-filled nota keeps 15500 and includes Usar dados da SEFAZ" do
    _account, organization = signed_in
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("nfce.jpg") }
    id = SupportingDocument.last.id
    install_a1(organization)
    stub_xml_consulta(nfce_chave, vnf: "100.00")

    patch "/supporting_documents/#{id}", params: { chave: nfce_chave }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
    get "/supporting_documents/#{id}/edit"
    expect(response.body).to include("Usar dados da SEFAZ")
  end

  it "confirm identified SEFAZ on public-filled nota persists 10000" do
    _account, organization = signed_in
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("nfce.jpg") }
    id = SupportingDocument.last.id
    install_a1(organization)
    stub_xml_consulta(nfce_chave, vnf: "100.00")
    patch "/supporting_documents/#{id}", params: { chave: nfce_chave }

    post "/supporting_documents/#{id}/sefaz_confirm"

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).amount_cents).to eq(10000)
    patch "/supporting_documents/#{id}", params: { amount: "200,00" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Valor, data e favorecido vêm da nota e não podem ser alterados")
  end

  it "PATCH kind nota_fiscal on recibo with photo chave returns 422 KIND_LOCKED" do
    _account, organization = signed_in
    stub_photo_symbols("recibo.jpg", chave: nfe_chave)
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00", emit: "Mercado Silva", dhemi: "2026-05-12T10:00:00-03:00")
    post "/supporting_documents", params: recibo_params
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { kind: "nota_fiscal" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq(SupportingDocument::KIND_LOCKED)
    expect(SupportingDocument.find(id).kind).to eq("recibo")
  end

  it "PATCH kind recibo on photo-filled nota returns 422 KIND_LOCKED" do
    signed_in
    stub_photo_fields("fields.jpg")
    stub_photo_symbols("fields.jpg", chave: nfe_chave)
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("fields.jpg") }
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { kind: "recibo" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq(SupportingDocument::KIND_LOCKED)
    expect(SupportingDocument.find(id).kind).to eq("nota_fiscal")
  end

  it "install A1 after photo-filled chave does not retro-consult" do
    _account, organization = signed_in
    stub_photo_fields("fields.jpg")
    stub_photo_symbols("fields.jpg", chave: nfe_chave)
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("fields.jpg") }
    id = SupportingDocument.last.id
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")

    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
  end

  it "PATCH chave on closed-month photo-filled document returns 422" do
    _account, organization = signed_in
    stub_photo_fields("fields.jpg")
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("fields.jpg") }
    document = SupportingDocument.last
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 15500)
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
    month.update!(closed: true)

    patch "/supporting_documents/#{document.id}", params: { chave: nfe_chave }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(document.reload.chave).to be_nil
  end

  it "unauthenticated POST nota photo responds 302 to /login" do
    stub_photo_fields("fields.jpg")

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("fields.jpg") }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(SupportingDocument.count).to eq(0)
  end

  it "submitter PATCH chave on another Account photo-filled document returns 404" do
    coord, organization = plant_coordinator
    stub_photo_fields("fields.jpg")
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(coord, organization: organization)
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("fields.jpg") }
    id = SupportingDocument.last.id
    sign_in_as(submitter, organization: organization)

    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }

    expect(response).to have_http_status(:not_found)
    expect(SupportingDocument.find(id).chave).to be_nil
  end

  it "POST duplicate photo chave persists two SupportingDocuments" do
    _account, organization = signed_in
    stub_photo_symbols("a.jpg", chave: nfe_chave)
    stub_photo_symbols("b.jpg", chave: nfe_chave)
    install_a1(organization)
    stub_xml_consulta

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_named("a.jpg") }
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_named("b.jpg") }

    expect(SupportingDocument.where(organization: organization, chave: nfe_chave).count).to eq(2)
  end

  it "POST nota photo all extracts missing keeps include form fields" do
    signed_in

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("empty.jpg") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Informe valor, data e favorecido")
    expect(response.body).to include('id="amount"')
    expect(response.body).to include('id="date"')
    expect(response.body).to include('id="payee"')
    expect(response.body).to include('id="file"')
  end

  it "confirm identified SEFAZ on photo-filled nota when consulta errors returns 422" do
    _account, organization = signed_in
    stub_photo_fields("fields.jpg")
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("fields.jpg") }
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Error.new)

    post "/supporting_documents/#{id}/sefaz_confirm"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Não foi possível consultar a SEFAZ")
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }
    expect(response).to have_http_status(:found)
  end

  it "POST recibo amount 1,00 persists 100 cents" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params(amount: "1,00")

    expect(SupportingDocument.where(organization: organization).count).to eq(1)
    expect(SupportingDocument.last.amount_cents).to eq(100)
  end

  it "GET coordinator amount fields have inputmode numeric" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents"

    page = page_doc(response.body)
    expect(page.at_css("#amount")["inputmode"]).to eq("numeric")
  end

  it "GET submitter justification amount fields have inputmode numeric" do
    account, organization = signed_submitter
    post "/supporting_documents", params: recibo_params(payee: "Padaria Central")
    document = SupportingDocument.last
    Justification.declare(organization: organization, account: account, amount: "300,00", supporting_document_ids: [ document.id ])
    justification = Justification.last

    get "/supporting_documents"

    page = page_doc(response.body)
    expect(page.at_css("#justification_amount")["inputmode"]).to eq("numeric")
    expect(page.at_css("#justification_amount_#{justification.id}")["inputmode"]).to eq("numeric")
  end

  it "GET Sem mes head is Data Favorecido Tipo Valor Acoes" do
    account, organization = signed_in
    plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents"

    texts = page_doc(response.body).at_css(".ledger-head.ledger-doc").element_children.map { |node| node.text.strip }
    expect(texts).to eq([ "Data", "Favorecido", "Tipo", "Valor", "Ações" ])
  end

  it "GET Sem mes row Tipo Recibo and filename under Favorecido" do
    account, organization = signed_in
    document = SupportingDocument.insert(
      organization: organization,
      account: account,
      kind: "recibo",
      amount: "155,00",
      date: "2026-05-11",
      payee: "Padaria Central",
      photo: photo_named("foto.jpg")
    )

    get "/supporting_documents"

    document_row = row(response.body, "document", document_id: document.id)
    expect(document_row.at_css('[data-cell="kind"]').text.strip).to eq("Recibo")
    payee = document_row.at_css('[data-cell="payee"]')
    expect(payee.text).to include("Padaria Central")
    expect(payee.text).to include("foto.jpg")
    expect(payee.text).not_to include("Recibo")
  end

  it "GET Editar is a link to edit not a details fold" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents"

    document_row = row(response.body, "document", document_id: document.id)
    link = editar_link(document_row)
    expect(link.text.strip).to eq("Editar")
    expect(link["href"]).to eq("/supporting_documents/#{document.id}/edit")
    expect(link.ancestors.include?(document_row.at_css('[data-cell="actions"]'))).to eq(true)
    expect(link.ancestors.include?(document_row.at_css('[data-cell="payee"]'))).to eq(false)
    expect(document_row.css("details").none? { |node| node.at_css("summary")&.text&.strip == "Editar" }).to eq(true)
    expect(document_row.css("form").none? { |form| form.at_css('input[name="_method"][value="patch"]') }).to eq(true)
  end

  it "GET Excluir sits in Acoes not inside Editar" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents"

    document_row = row(response.body, "document", document_id: document.id)
    excluir = document_row.css("button").find { |button| button.text.strip == "Excluir" }
    expect(excluir).not_to be_nil
    form = excluir.ancestors("form").first
    expect(form["action"]).to eq("/supporting_documents/#{document.id}")
    expect(form.at_css('input[name="_method"][value="delete"]')).not_to be_nil
    expect(form["data-turbo-confirm"]).to eq("Excluir este documento?")
    expect(excluir.ancestors.include?(document_row.at_css('[data-cell="actions"]'))).to eq(true)
  end

  it "GET month-assigned row has Editar and no Excluir" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    month, _statement = plant_month(organization)
    document.update!(month_id: month.id)

    get "/supporting_documents"

    document_row = row(response.body, "document", document_id: document.id)
    expect(editar_link(document_row)["href"]).to eq("/supporting_documents/#{document.id}/edit")
    expect(document_row.css("button").none? { |button| button.text.strip == "Excluir" }).to eq(true)
  end

  it "GET edit attached photo shows img filename and PHOTO_LOCKED" do
    signed_in
    post "/supporting_documents", params: recibo_params(photo: photo_named("foto-antiga.jpg"))
    id = SupportingDocument.last.id

    get "/supporting_documents/#{id}/edit"

    proof = page_doc(response.body).at_css("[data-edit=proof]")
    img = proof.at_css("img")
    expect(img).not_to be_nil
    expect(img["src"]).to include("rails/active_storage")
    expect(proof.text).to include("foto-antiga.jpg")
    expect(proof.text).to include(SupportingDocument::PHOTO_LOCKED)
    expect(page_doc(response.body).at_css("input#photo")).to be_nil
  end

  it "GET edit xml-only empty photo and locked XML" do
    signed_in
    post "/supporting_documents", params: nota_params(xml: authorized_xml)
    id = SupportingDocument.last.id

    get "/supporting_documents/#{id}/edit"

    page = page_doc(response.body)
    proof = page.at_css("[data-edit=proof]")
    expect(proof.text).to include("Nenhuma foto")
    expect(proof.text).to include("autorizada.xml")
    expect(page.at_css("input#photo")).to be_nil
    expect(page.at_css("input#xml")).to be_nil
    expect(page.at_css("#arquivo")["value"]).to eq("XML")
  end

  it "PATCH new photo on attached photo returns 422 and keeps filename" do
    signed_in
    post "/supporting_documents", params: recibo_params(photo: photo_named("foto-antiga.jpg"))
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { photo: photo_named("foto-nova.jpg") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("Editar documento")
    expect(error_notice_text(response.body)).to eq(SupportingDocument::PHOTO_LOCKED)
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include(SupportingDocument::PHOTO_LOCKED)
    expect(SupportingDocument.find(id).photo.filename.to_s).to eq("foto-antiga.jpg")
  end

  it "PATCH empty-slot photo on xml-only nota_fiscal attaches and keeps xml" do
    signed_in
    post "/supporting_documents", params: nota_params(xml: authorized_xml)
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { photo: photo_named("recibo-novo.jpg") }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    doc = SupportingDocument.find(id)
    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.photo.filename.to_s).to eq("recibo-novo.jpg")
    expect(doc.xml.filename.to_s).to eq("autorizada.xml")
  end

  it "PATCH new XML on attached XML returns 422 and keeps filename" do
    signed_in
    post "/supporting_documents", params: nota_params(xml: authorized_xml)
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { xml: xml_file("outra.xml") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq(SupportingDocument::XML_LOCKED)
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include(SupportingDocument::XML_LOCKED)
    expect(SupportingDocument.find(id).xml.filename.to_s).to eq("autorizada.xml")
  end

  it "GET insert photo is empty with Limpar" do
    signed_submitter

    get "/supporting_documents"

    form = insert_form(response.body)
    expect(form.at_css("#file")).not_to be_nil
    expect(form.at_css("#file")["disabled"]).to be_nil
  end

  it "GET Editar kind is disabled and insert kind stays enabled" do
    account, organization = signed_in
    recibo = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    nf = SupportingDocument.insert(
      organization: organization,
      account: account,
      kind: "nota_fiscal",
      amount: "155,00",
      date: "2026-05-11",
      payee: "Mercado Silva",
      photo: photo_jpg("nota.jpg")
    )

    sign_in_as(plant_submitter(organization: organization).first, organization: organization)
    get "/supporting_documents"
    expect(insert_form(response.body).at_css("#kind")["disabled"]).to be_present
    sign_in_as(account, organization: organization)

    get "/supporting_documents/#{recibo.id}/edit"
    page = page_doc(response.body)
    expect(page.at_css("#kind")["disabled"]).to be_present
    expect(page.at_css("#chave")).to be_nil
    expect(page.at_css("#xml")).to be_nil

    get "/supporting_documents/#{nf.id}/edit"
    page = page_doc(response.body)
    expect(page.at_css("#kind")["disabled"]).to be_present
    expect(html_visible?(page.at_css("#chave"))).to be true
    expect(page.at_css("#xml")).to be_nil
  end

  it "PATCH kind recibo on nota_fiscal returns 422 and keeps kind" do
    signed_in
    post "/supporting_documents", params: nota_params(xml: authorized_xml)
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { kind: "recibo" }

    expect(SupportingDocument.find(id).kind).to eq("nota_fiscal")
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq(SupportingDocument::KIND_LOCKED)
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include(SupportingDocument::KIND_LOCKED)
  end

  it "PATCH kind nota_fiscal on recibo returns 422 and keeps kind" do
    signed_in
    post "/supporting_documents", params: recibo_params
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { kind: "nota_fiscal" }

    expect(SupportingDocument.find(id).kind).to eq("recibo")
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq(SupportingDocument::KIND_LOCKED)
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include(SupportingDocument::KIND_LOCKED)
  end

  it "POST recibo amount 0,00 returns 422 Informe valor, data e favorecido" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params(amount: "0,00")

    expect(SupportingDocument.where(organization: organization).count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Informe valor, data e favorecido")
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include("Informe valor, data e favorecido")
  end

  it "GET insert kind has empty selection and both options" do
    signed_submitter

    get "/supporting_documents"

    kind = insert_form(response.body).at_css("select#kind")
    expect(html_visible?(kind)).to eq(false)
    expect(kind.at_css('option[value="nota_fiscal"]').text.strip).to eq("Nota fiscal")
    expect(kind.at_css('option[value="recibo"]').text.strip).to eq("Recibo")
  end

  it "GET insert empty kind hides chave and xml" do
    signed_submitter

    get "/supporting_documents"

    form = insert_form(response.body)
    expect(html_visible?(form.at_css("#chave"))).to be false
    expect(form.at_css("#xml")).to be_nil
    expect(form.at_css("#file")).not_to be_nil
  end

  it "POST empty kind photo chave infers Nota fiscal" do
    _account, organization = signed_in
    stub_photo_symbols("recibo.jpg", chave: nfe_chave)

    post "/supporting_documents", params: {
      kind: "", amount: "155,00", date: "2026-05-11", payee: "Padaria Central", photo: photo_jpg("recibo.jpg")
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    expect(SupportingDocument.where(organization: organization).count).to eq(1)
    document = SupportingDocument.last
    expect(document.kind).to eq("nota_fiscal")
    expect(document.chave).to eq(nfe_chave)

    get "/supporting_documents"
    expect(row(response.body, "document", document_id: document.id).at_css('[data-cell="kind"]').text.strip).to eq("Nota fiscal")
  end

  it "POST empty kind photo miss infers Recibo" do
    _account, organization = signed_in
    stub_photo_symbols("recibo.jpg", chave: nil, qr_url: nil)

    post "/supporting_documents", params: {
      kind: "", amount: "155,00", date: "2026-05-11", payee: "Padaria Central", photo: photo_jpg("recibo.jpg")
    }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.where(organization: organization).count).to eq(1)
    document = SupportingDocument.last
    expect(document.kind).to eq("recibo")
    expect(document.chave).to be_nil
    expect(document.xml).not_to be_attached

    get "/supporting_documents"
    expect(row(response.body, "document", document_id: document.id).at_css('[data-cell="kind"]').text.strip).to eq("Recibo")
  end

  it "POST empty kind XML infers nota_fiscal uploaded_xml" do
    _account, organization = signed_in

    post "/supporting_documents", params: { kind: "", xml: authorized_xml }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.where(organization: organization).count).to eq(1)
    document = SupportingDocument.last
    expect(document.kind).to eq("nota_fiscal")
    expect(document.chave).to eq(nfe_chave)
    expect(document.amount_cents).to eq(15500)
    expect(document.fields_origin).to eq("uploaded_xml")
  end

  it "POST empty kind XML chave wins over photo chave" do
    signed_in
    stub_photo_symbols("danfe.jpg", chave: other_chave)

    post "/supporting_documents", params: {
      kind: "", xml: authorized_xml
    }

    expect(response).to have_http_status(:found)
    document = SupportingDocument.last
    expect(document.kind).to eq("nota_fiscal")
    expect(document.chave).to eq(nfe_chave)
  end

  it "POST empty kind photo QR infers nota_fiscal" do
    signed_in
    stub_photo_symbols("recibo.jpg", chave: nfce_chave, qr_url: nfce_qr_url)

    post "/supporting_documents", params: {
      kind: "", amount: "155,00", date: "2026-05-11", payee: "Padaria Central", photo: photo_jpg("recibo.jpg")
    }

    document = SupportingDocument.last
    expect(document.kind).to eq("nota_fiscal")
    expect(document.chave).to eq(nfce_chave)
  end

  it "POST empty kind photo QR without chave infers nota_fiscal" do
    signed_in
    stub_photo_symbols("recibo.jpg", chave: nil, qr_url: nfce_qr_url)

    post "/supporting_documents", params: {
      kind: "", amount: "155,00", date: "2026-05-11", payee: "Padaria Central", photo: photo_jpg("recibo.jpg")
    }

    expect(SupportingDocument.last.kind).to eq("nota_fiscal")
  end

  it "POST empty kind without file returns 422 Informe se e nota fiscal ou recibo" do
    _account, organization = signed_in

    post "/supporting_documents", params: { kind: "", amount: "155,00", date: "2026-05-11", payee: "Padaria Central" }

    expect(SupportingDocument.where(organization: organization).count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq(SupportingDocument::NF_FILES)
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include(SupportingDocument::NF_FILES)
  end

  it "POST kind recibo keeps recibo when photo has chave" do
    signed_in
    stub_photo_symbols("recibo.jpg", chave: nfe_chave)

    post "/supporting_documents", params: recibo_params(photo: photo_jpg("recibo.jpg"))

    document = SupportingDocument.last
    expect(document.kind).to eq("recibo")
    expect(document.chave).to be_nil
    expect(document.xml).not_to be_attached
  end

  it "POST kind nota_fiscal keeps nota_fiscal on photo miss" do
    signed_in
    stub_photo_symbols("recibo.jpg", chave: nil, qr_url: nil)

    post "/supporting_documents", params: nota_params(photo: photo_jpg("recibo.jpg"))

    expect(SupportingDocument.last.kind).to eq("nota_fiscal")
  end

  it "POST kind invoice with photo returns 422 Informe se e nota fiscal ou recibo" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params.merge(kind: "invoice")

    expect(SupportingDocument.where(organization: organization).count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq(SupportingDocument::BAD_KIND)
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include(SupportingDocument::BAD_KIND)
  end

  it "POST empty kind photo fields origin photo then PATCH payee redirects" do
    signed_in
    stub_photo_symbols("recibo.jpg", chave: nfe_chave)
    stub_photo_fields("recibo.jpg")

    post "/supporting_documents", params: { kind: "", photo: photo_jpg("recibo.jpg") }

    document = SupportingDocument.last
    expect(document.kind).to eq("nota_fiscal")
    expect(document.amount_cents).to eq(15500)
    expect(document.document_on).to eq(Date.new(2026, 5, 11))
    expect(document.payee).to eq("Padaria Central")
    expect(document.fields_origin).to eq("photo")
    patch "/supporting_documents/#{document.id}", params: { payee: "Mercado Silva" }
    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(document.id).payee).to eq("Mercado Silva")
  end

  it "POST empty kind photo miss keeps typed payee" do
    signed_in
    stub_photo_symbols("recibo.jpg", chave: nil, qr_url: nil)

    post "/supporting_documents", params: {
      kind: "", amount: "155,00", date: "2026-05-11", payee: "Padaria Central", photo: photo_jpg("recibo.jpg")
    }

    document = SupportingDocument.last
    expect(document.payee).to eq("Padaria Central")
    expect(document.fields_origin).to eq("typed")
  end

  it "GET edit coordinator 200 Editar documento" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents/#{document.id}/edit"

    expect(response).to have_http_status(:ok)
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("Editar documento")
  end

  it "unauthenticated GET edit responds 302 to /login" do
    account, organization = plant_coordinator
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents/#{document.id}/edit"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "submitter GET edit on another Account document returns 404" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(coord, organization: organization)
    post "/supporting_documents", params: recibo_params
    id = SupportingDocument.last.id
    sign_in_as(submitter, organization: organization)

    get "/supporting_documents/#{id}/edit"

    expect(response).to have_http_status(:not_found)
  end

  it "submitter GET edit on own document returns 200" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    post "/supporting_documents", params: recibo_params
    id = SupportingDocument.last.id

    get "/supporting_documents/#{id}/edit"

    expect(response).to have_http_status(:ok)
  end

  it "GET edit missing id returns 404" do
    signed_in

    get "/supporting_documents/0/edit"

    expect(response).to have_http_status(:not_found)
  end

  it "GET edit other organization document returns 404" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    sign_in_as(account, organization: org_b)
    post "/supporting_documents", params: recibo_params(payee: "Only Org B")
    id = SupportingDocument.last.id
    sign_in_as(account, organization: org_a)

    get "/supporting_documents/#{id}/edit"

    expect(response).to have_http_status(:not_found)
  end

  it "GET edit page order Voltar h1 split proof then book" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents/#{document.id}/edit"

    main = page_doc(response.body).at_css("main")
    voltar = main.css("a").find { |node| node.text.strip == "Voltar para documentos" }
    expect(voltar["href"]).to eq("/supporting_documents")
    h1 = main.at_css("h1")
    expect(h1.text.strip).to eq("Editar documento")
    expect(main.inner_html.index("Voltar para documentos")).to be < main.inner_html.index("<h1")
    form = main.at_css("form#document-edit")
    expect(form.at_css('label[for="kind"]').text.strip).to eq("Tipo")
    expect(form.at_css('label[for="amount"]').text.strip).to eq("Valor")
    expect(form.at_css('label[for="date"]').text.strip).to eq("Data")
    expect(form.at_css('label[for="payee"]').text.strip).to eq("Favorecido")
    expect(form.at_css('label[for="observation"]').text.strip).to eq("Observação (opcional)")
    expect(form.at_css("#kind")["disabled"]).to be_present
    expect(form.at_css('input[type="submit"][value="Salvar documento"]')).not_to be_nil
    book = main.at_css("[data-edit=book]")
    expect(book["class"]).to include("max-w-[28rem]")
    expect(book.at_css("form#document-edit")).not_to be_nil
    split = main.at_css("[data-edit=split]")
    expect(split["class"]).to include("md:grid-cols-[minmax(0,1fr)_28rem]")
    children = split.element_children
    expect(children[0]["data-edit"]).to eq("proof")
    expect(children[1]["data-edit"]).to eq("book")
    expect(main.inner_html.index("<h1")).to be < main.inner_html.index("data-edit=\"split\"")
  end

  it "GET edit pending SEFAZ notice and button before split" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }
    expect(SupportingDocument.find(id).sefaz_confirm_pending?).to eq(true)

    get "/supporting_documents/#{id}/edit"

    main = page_doc(response.body).at_css("main")
    expect(main.text).to include("A SEFAZ devolveu dados desta chave.")
    sefaz = main.css("form").find { |form| form["action"] == "/supporting_documents/#{id}/sefaz_confirm" }
    expect(sefaz.at_css("button").text.strip).to eq("Usar dados da SEFAZ")
    html = main.inner_html
    expect(html.index("<h1")).to be < html.index("A SEFAZ devolveu dados desta chave.")
    expect(html.index("A SEFAZ devolveu dados desta chave.")).to be < html.index("data-edit=\"split\"")
  end

  it "GET edit without pending SEFAZ has no Usar dados" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents/#{document.id}/edit"

    expect(response.body).not_to include("Usar dados da SEFAZ")
    expect(response.body).not_to include("A SEFAZ devolveu dados desta chave.")
  end

  it "GET edit typed shows amount date payee" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents/#{document.id}/edit"

    page = page_doc(response.body)
    expect(page.at_css("#amount")["disabled"]).to be_nil
    expect(page.at_css("#date")["disabled"]).to be_nil
    expect(page.at_css("#payee")["disabled"]).to be_nil
  end

  it "GET edit locked XML hides amount date payee" do
    signed_in
    post "/supporting_documents", params: nota_params(xml: authorized_xml)
    id = SupportingDocument.last.id
    expect(SupportingDocument.find(id).fields_locked?).to eq(true)

    get "/supporting_documents/#{id}/edit"

    page = page_doc(response.body)
    expect(page.at_css("#amount")["disabled"]).to be_present
    expect(page.at_css("#date")["disabled"]).to be_present
    expect(page.at_css("#payee")["disabled"]).to be_present
  end

  it "GET edit Excluir when month_id nil" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents/#{document.id}/edit"

    page = page_doc(response.body)
    excluir = page.css("button").find { |button| button.text.strip == "Excluir" }
    form = page.at_css("form##{excluir['form']}")
    expect(form["action"]).to eq("/supporting_documents/#{document.id}")
    expect(form.at_css('input[name="_method"][value="delete"]')).not_to be_nil
    expect(form["data-turbo-confirm"]).to eq("Excluir este documento?")
  end

  it "GET edit no Excluir when month_id set" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    month, _statement = plant_month(organization)
    document.update!(month_id: month.id)

    get "/supporting_documents/#{document.id}/edit"

    expect(page_doc(response.body).css("button").none? { |button| button.text.strip == "Excluir" }).to eq(true)
  end

  it "GET edit chave field keeps raw digits" do
    signed_in
    chave = "35240612345678000190550010000012341000012340"
    post "/supporting_documents", params: nota_params(photo: photo_jpg, chave: chave)
    id = SupportingDocument.last.id

    get "/supporting_documents/#{id}/edit"

    expect(page_doc(response.body).at_css("#chave")["value"]).to eq(chave)
  end

  it "GET edit amount has inputmode numeric" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents/#{document.id}/edit"

    expect(page_doc(response.body).at_css("#amount")["inputmode"]).to eq("numeric")
  end

  it "GET edit Salvar and Excluir share actions row in book" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents/#{document.id}/edit"

    book = page_doc(response.body).at_css("[data-edit=book]")
    actions = book.at_css("[data-edit=actions]")
    salvar = actions.at_css('input[type="submit"][value="Salvar documento"]')
    excluir = actions.css("button").find { |button| button.text.strip == "Excluir" }
    expect(salvar).not_to be_nil
    expect(excluir).not_to be_nil
    html = actions.inner_html
    expect(html.index("Salvar documento")).to be < html.index("Excluir")
  end

  it "GET edit empty XML label XML and Limpar" do
    account, organization = signed_in
    document = SupportingDocument.insert(
      organization: organization,
      account: account,
      kind: "nota_fiscal",
      amount: "155,00",
      date: "2026-05-11",
      payee: "Padaria Central",
      photo: photo_jpg
    )

    get "/supporting_documents/#{document.id}/edit"

    page = page_doc(response.body)
    expect(page.at_css('label[for="xml"]')).to be_nil
    expect(page.at_css("#arquivo")["value"]).to eq("Foto")
  end

  it "DELETE month document 422 renders index not edit" do
    account, organization = signed_in
    post "/supporting_documents", params: recibo_params(amount: "220,00")
    document = SupportingDocument.last
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    delete "/supporting_documents/#{document.id}"

    expect(response).to have_http_status(:unprocessable_content)
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("Documentos de suporte")
  end

  it "POST sefaz_confirm uploaded XML 422 renders index not edit" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00", emit: "Outro")
    post "/supporting_documents", params: {
      kind: "nota_fiscal", xml: authorized_xml(vnf: "155.00"), chave: nfe_chave
    }
    id = SupportingDocument.last.id

    post "/supporting_documents/#{id}/sefaz_confirm"

    expect(response).to have_http_status(:unprocessable_content)
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("Documentos de suporte")
  end
end
