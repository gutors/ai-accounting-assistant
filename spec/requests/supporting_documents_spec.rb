require "rails_helper"

RSpec.describe "Supporting documents", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  def signed_in
    account, organization = plant_coordinator
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


  it "unauthenticated GET /supporting_documents responds 302 to /login" do
    get "/supporting_documents"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "GET /supporting_documents without focus responds 302 to /login" do
    account, organization = plant_coordinator(email: "coord@example.com")
    other = Account.create!(email: "other@example.com", google_uid: "uid-other")
    Access.create!(account: other, organization: organization, kind: :coordinator)
    sign_in_as(account, organization: organization)
    Access.where(account: account).delete_all

    get "/supporting_documents"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "GET /supporting_documents responds 200 with pt-BR and Documentos de suporte" do
    signed_in

    get "/supporting_documents"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('lang="pt-BR"')
    expect(response.body).to include("Documentos de suporte")
  end

  it "GET /supporting_documents with no documents includes Nenhum documento" do
    signed_in

    get "/supporting_documents"

    expect(response.body).to include("Nenhum documento")
  end

  it "GET /supporting_documents with no Month responds 200" do
    signed_in

    get "/supporting_documents"

    expect(response).to have_http_status(:ok)
    expect(Month.count).to eq(0)
  end

  it "documents page does not include another organization payee" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    sign_in_as(account, organization: org_b)
    post "/supporting_documents", params: recibo_params(payee: "Only Org B")

    sign_in_as(account, organization: org_a)
    get "/supporting_documents"

    expect(response.body).not_to include("Only Org B")
  end

  it "POST recibo jpg persists Padaria Central Recibo and redirects" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params(photo: photo_jpg("recibo.jpg"))

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    expect(SupportingDocument.where(organization: organization).count).to eq(1)

    get "/supporting_documents"
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
    list = response.body[response.body.index("Sem mês")..]
    document_row = rows(list, "document").first
    expect(document_row.at_css('time[datetime="2026-05-11"]').text).to eq("11/05/2026")
    expect(document_row.text).to include("R$ 155,00", "Recibo", "Padaria Central")
    expect(list).to include("recibo.jpg")
  end

  it "POST recibo belongs to inserting Account and creates no Month" do
    account, _organization = signed_in

    expect do
      post "/supporting_documents", params: recibo_params
    end.not_to change(Month, :count)

    expect(SupportingDocument.last.account).to eq(account)
  end

  it "GET insert date defaults to Date.current" do
    signed_in

    travel_to Date.new(2026, 10, 5) do
      get "/supporting_documents"
    end

    expect(response).to have_http_status(:ok)
    form = insert_form(response.body)
    expect(form.at_css('label[for="date"]').text.strip).to eq("Data")
    date = form.at_css("input#date[type=date]")
    expect(html_visible?(date)).to eq(false)
  end

  it "GET Editar date stays document_on" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00", date: "2026-05-11")

    travel_to Date.new(2026, 10, 5) do
      get "/supporting_documents/#{document.id}/edit"
    end

    date = page_doc(response.body).at_css("input#date[type=date]")
    expect(date["value"]).to eq("2026-05-11")
  end

  it "GET optional chave and observation labels on insert and Editar" do
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

    travel_to Date.new(2026, 10, 5) do
      get "/supporting_documents"
    end

    form = insert_form(response.body)
    expect(form.at_css('label[for="chave"]').text.strip).to eq("Chave de acesso (opcional)")
    expect(form.at_css('label[for="observation"]').text.strip).to eq("Observação (opcional)")

    get "/supporting_documents/#{document.id}/edit"
    page = page_doc(response.body)
    expect(page.at_css('label[for="chave"]').text.strip).to eq("Chave de acesso (opcional)")
    expect(page.at_css('label[for="observation"]').text.strip).to eq("Observação (opcional)")
  end

  it "GET insert kind nota_fiscal shows chave and xml" do
    signed_in

    get "/supporting_documents"

    page = page_doc(response.body)
    first_section = page.css("section").first
    form = first_section.css("form").find { |node| node["action"] == "/supporting_documents" && node["method"] == "post" }
    expect(form).not_to be_nil
    expect(form["class"]).to include("md:grid-cols-[minmax(0,1fr)_28rem]")
    expect(form.at_css('input[type="submit"][value="Incluir documento"]')).not_to be_nil
    expect(form.at_css('label[for="photo"]')).to be_nil
    expect(form.at_css('label[for="xml"]')).to be_nil
    expect(form.css('input[type="file"]').size).to eq(1)
    expect(html_visible?(form.at_css("select#kind"))).to eq(false)
    chave = form.at_css("input#chave")
    expect(chave).not_to be_nil
    expect(html_visible?(chave)).to eq(false)
  end

  def limpar_next_to(form, input_id)
    input = form.at_css("##{input_id}")
    buttons = input.parent.css("button").select { |button| button.text.strip == "Limpar" && button["type"] == "button" }
    expect(buttons.size).to eq(1)
    buttons.first
  end

  def echoed_insert_fields(body)
    form = insert_form(body)
    {
      kind: selected_option_value(form.at_css("select#kind")),
      amount: form.at_css("#amount")["value"].to_s,
      date: form.at_css("#date")["value"].to_s,
      payee: form.at_css("#payee")["value"].to_s,
      observation: form.at_css("#observation").text,
      chave: form.at_css("#chave")["value"].to_s,
      photo: form.at_css("#file"),
      xml: form.at_css("#file")
    }
  end

  def session_blob_stash(organization)
    {
      blobs: ActiveStorage::Blob.count,
      sefaz: organization.reload.attributes.values_at(
        "sefaz_titular_cnpj", "sefaz_not_after", "sefaz_pkcs12_ciphertext", "sefaz_passphrase_ciphertext"
      ),
      session: session.to_hash.values
    }
  end

  def expect_echoed_document_texts(fields)
    expect(fields[:amount]).to eq("155,00")
    expect(fields[:date]).to eq("2026-05-11")
    expect(fields[:payee]).to eq("Padaria Central")
    expect(fields[:observation].strip).to eq("pago em dinheiro")
  end

  def expect_empty_file_input(node)
    expect(node["type"]).to eq("file")
    expect(node["value"].to_s).to eq("")
  end

  def expect_no_stash(before, organization, passphrase: nil, der: nil)
    after = session_blob_stash(organization)
    expect(after[:blobs]).to eq(before[:blobs])
    expect(after[:sefaz]).to eq(before[:sefaz])
    joined = after[:session].map { |value| value.to_s }.join
    expect(joined).not_to include(passphrase) if passphrase
    expect(after[:session].none? { |value| value.to_s.b.include?(der.b) }).to eq(true) if der
  end

  it "GET insert has Limpar next to photo and xml" do
    signed_in

    get "/supporting_documents"

    form = insert_form(response.body)
    expect(form.at_css("#file")).not_to be_nil
    expect(form.css("button").none? { |button| html_visible?(button) && button.text.strip == "Limpar" }).to eq(true)
    notice = error_notice(response.body)
    expect(notice.attribute("hidden")).not_to be_nil
    expect(notice.parent.name).to eq("main")
    expect(page_doc(response.body).at_css("#toast-host")).not_to be_nil
    expect(toast_node(response.body)).to be_nil
  end

  it "GET edit recibo hides chave and xml" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents/#{document.id}/edit"

    page = page_doc(response.body)
    expect(selected_option_value(page.at_css("select#kind"))).to eq("recibo")
    expect(page.at_css("input#chave")).to be_nil
    expect(page.at_css("input#xml")).to be_nil
    expect(page.at_css("input#photo")).to be_nil
  end

  it "GET edit nota_fiscal shows chave and empty XML" do
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
    expect(selected_option_value(page.at_css("select#kind"))).to eq("nota_fiscal")
    expect(page.at_css('label[for="chave"]').text.strip).to eq("Chave de acesso (opcional)")
    chave = page.at_css("input#chave")
    expect(html_visible?(chave)).to be true
    expect(page.at_css("input#xml")).to be_nil
    expect(page.at_css("#arquivo")["value"]).to eq("Foto")
  end

  it "POST recibo photo without XML persists chave nil and Pronto toast" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params(photo: photo_jpg("recibo.jpg"))

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    document = SupportingDocument.find_by!(organization: organization)
    expect(document.chave).to be_nil
    expect(document.xml).not_to be_attached

    get "/supporting_documents"
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
  end

  it "POST nota_fiscal chave 123 returns 422 and error toast" do
    _account, organization = signed_in

    post "/supporting_documents", params: nota_params(photo: photo_jpg, chave: "123")

    expect(SupportingDocument.where(organization: organization).count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Informe a chave de acesso com 44 dígitos")
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include("Informe a chave de acesso com 44 dígitos")
  end

  it "POST recibo with XML returns 422 and error toast" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params(photo: nil, xml: xml_file)

    expect(SupportingDocument.where(organization: organization).count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Recibo não tem XML")
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include("Recibo não tem XML")
  end

  it "POST nota_fiscal without files echoes insert fields on 422" do
    _account, organization = signed_in
    before = session_blob_stash(organization)

    post "/supporting_documents", params: {
      kind: "nota_fiscal", amount: "155,00", date: "2026-05-11", payee: "Padaria Central",
      observation: "pago em dinheiro"
    }

    expect(SupportingDocument.where(organization: organization).count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Envie a foto ou o XML")
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include("Envie a foto ou o XML")
    fields = echoed_insert_fields(response.body)
    expect(fields[:kind]).to eq("nota_fiscal")
    expect_echoed_document_texts(fields)
    expect_empty_file_input(fields[:photo])
    expect_no_stash(before, organization)
  end

  it "POST recibo with XML echoes insert fields on 422 and creates no blob" do
    _account, organization = signed_in
    before = session_blob_stash(organization)

    post "/supporting_documents", params: recibo_params(
      photo: nil, xml: xml_file, observation: "pago em dinheiro"
    )

    expect(SupportingDocument.where(organization: organization).count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Recibo não tem XML")
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include("Recibo não tem XML")
    fields = echoed_insert_fields(response.body)
    expect(fields[:kind]).to eq("recibo")
    expect_echoed_document_texts(fields)
    expect_empty_file_input(fields[:xml])
    expect_no_stash(before, organization)
  end

  it "POST nota_fiscal chave 123 echoes chave and insert fields on 422" do
    _account, organization = signed_in
    before = session_blob_stash(organization)

    post "/supporting_documents", params: nota_params(
      photo: photo_jpg, chave: "123", observation: "pago em dinheiro"
    )

    expect(SupportingDocument.where(organization: organization).count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Informe a chave de acesso com 44 dígitos")
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include("Informe a chave de acesso com 44 dígitos")
    fields = echoed_insert_fields(response.body)
    expect(fields[:kind]).to eq("nota_fiscal")
    expect(fields[:chave]).to eq("123")
    expect_echoed_document_texts(fields)
    expect_no_stash(before, organization)
  end

  it "POST nota_fiscal without files turbo stream 422 updates notice and toast only" do
    signed_in

    post "/supporting_documents", params: {
      kind: "nota_fiscal", amount: "155,00", date: "2026-05-11", payee: "Padaria Central",
      observation: "pago em dinheiro"
    }, headers: turbo_stream_accept

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.media_type).to include("turbo-stream")
    notice = turbo_stream_for(response.body, "[data-notice=error]")
    toast = turbo_stream_for(response.body, "toast-host")
    expect(notice.text).to include("Envie a foto ou o XML")
    expect(toast.text).to include("Envie a foto ou o XML")
    expect(Nokogiri::HTML::DocumentFragment.parse(response.body).at_css('form[action="/supporting_documents"]')).to be_nil
  end

  it "POST nota_fiscal 44-digit chave persists when consulta does not deliver" do
    _account, organization = signed_in

    post "/supporting_documents", params: nota_params(photo: photo_jpg("nota.jpg"), chave: nfe_chave)

    expect(SupportingDocument.where(organization: organization).count).to eq(1)
    expect(SupportingDocument.find_by!(organization: organization).chave).to eq("43260511222333000181550010000000011123456781")
  end

  # Ledger arrangement (visual-identity C44, C45, C47, C48)

  def editar_link(document_row)
    document_row.css("a").find { |node| node.text.strip == "Editar" }
  end

  it "documents h1 insert form first and edit folds under Editar" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents"

    expect(response).to have_http_status(:ok)
    page = page_doc(response.body)
    expect(page.at_css("h1").text.strip).to eq("Documentos de suporte")
    first_section = page.css("section").first
    insert_form = first_section.css("form").find { |node| node["action"] == "/supporting_documents" && node["method"] == "post" }
    expect(insert_form).not_to be_nil
    expect(insert_form.at_css('input[type="submit"][value="Incluir documento"]')).not_to be_nil

    document_row = row(response.body, "document", document_id: document.id)
    expect(document_row).not_to be_nil
    expect(editar_link(document_row)["href"]).to eq("/supporting_documents/#{document.id}/edit")
    expect(document_row.css("form").none? { |form| form.at_css('input[name="_method"][value="patch"]') }).to eq(true)
  end

  it "Excluir sits inside Editar" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents"

    document_row = row(response.body, "document", document_id: document.id)
    excluir = document_row.css("button").find { |button| button.text.strip == "Excluir" }
    expect(excluir).not_to be_nil
    expect(excluir.ancestors.include?(document_row.at_css('[data-cell="actions"]'))).to eq(true)
  end

  it "GET list row has no Usar dados da SEFAZ" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }
    expect(SupportingDocument.find(id).sefaz_confirm_pending?).to eq(true)

    get "/supporting_documents"

    document_row = row(response.body, "document", document_id: id)
    expect(document_row.text).not_to include("Usar dados da SEFAZ")
  end

  it "chave is displayed in groups of four and kept raw in the edit field" do
    signed_in
    chave = "35240612345678000190550010000012341000012340"
    post "/supporting_documents", params: nota_params(photo: photo_jpg, chave: chave)
    id = SupportingDocument.last.id
    expect(SupportingDocument.find(id).chave).to eq(chave)

    get "/supporting_documents"

    document_row = row(response.body, "document", document_id: id)
    expect(document_row.at_css("[data-chave]").text.strip).to eq("3524 0612 3456 7800 0190 5500 1000 0012 3410 0001 2340")

    get "/supporting_documents/#{id}/edit"
    expect(page_doc(response.body).at_css("input#chave")["value"]).to eq(chave)
  end

  it "document error renders as a data-notice error alert" do
    signed_in

    post "/supporting_documents", params: {
      kind: "recibo", amount: "155,00", date: "2026-05-11", payee: "Padaria Central"
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Envie a foto do recibo")
    toast = toast_node(response.body)
    expect(toast["data-toast-kind"]).to eq("error")
    expect(toast.text).to include("Envie a foto do recibo")
  end

  it "POST recibo without photo returns 422 Envie a foto do recibo" do
    _account, organization = signed_in

    post "/supporting_documents", params: {
      kind: "recibo", amount: "155,00", date: "2026-05-11", payee: "Padaria Central"
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Envie a foto do recibo")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "POST recibo with xml returns 422 Recibo nao tem XML" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params(photo: nil, xml: xml_file)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Recibo não tem XML")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "unauthenticated POST /supporting_documents responds 302 to /login" do
    expect do
      post "/supporting_documents", params: recibo_params
    end.not_to change(SupportingDocument, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "POST nota_fiscal photo persists Nota fiscal and filename" do
    signed_in

    post "/supporting_documents", params: nota_params(photo: photo_jpg("danfe.jpg"))

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    doc = SupportingDocument.last
    expect(doc.photo).to be_attached
    expect(doc.xml).not_to be_attached

    get "/supporting_documents"
    list = response.body[response.body.index("Sem mês")..]
    document_row = rows(list, "document").first
    expect(document_row.at_css('time[datetime="2026-05-11"]').text).to eq("11/05/2026")
    expect(document_row.text).to include("R$ 155,00", "Nota fiscal", "Padaria Central")
    expect(list).to include("danfe.jpg")
  end

  it "POST nota_fiscal xml persists xml filename" do
    signed_in

    post "/supporting_documents", params: nota_params(xml: authorized_xml("autorizada.xml"))

    expect(response).to have_http_status(:found)
    doc = SupportingDocument.last
    expect(doc.xml).to be_attached
    expect(doc.photo).not_to be_attached

    get "/supporting_documents"
    expect(response.body).to include("autorizada.xml")
  end

  it "POST nota_fiscal photo and xml persists both blobs" do
    signed_in

    post "/supporting_documents", params: nota_params(photo: photo_jpg, xml: authorized_xml)

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Envie a foto ou o XML")
    expect(SupportingDocument.count).to eq(0)
  end

  it "POST nota_fiscal without files returns 422 Envie a foto ou o XML" do
    _account, organization = signed_in

    post "/supporting_documents", params: nota_params

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Envie a foto ou o XML")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "POST authorized XML with typed 100,00 persists 15500" do
    signed_in

    post "/supporting_documents", params: nota_params(amount: "100,00", xml: authorized_xml)

    expect(SupportingDocument.last.amount_cents).to eq(15500)
  end

  it "GET /supporting_documents lists 12/05/2026 before 11/05/2026" do
    signed_in
    post "/supporting_documents", params: recibo_params(date: "2026-05-11", payee: "Primeiro")
    post "/supporting_documents", params: recibo_params(date: "2026-05-12", payee: "Segundo")

    get "/supporting_documents"

    expect(response.body.index("12/05/2026")).to be < response.body.index("11/05/2026")
  end

  it "POST duplicate amount date payee persists both" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params
    post "/supporting_documents", params: recibo_params

    expect(SupportingDocument.where(organization: organization).count).to eq(2)
  end

  it "PATCH payee to Mercado Silva redirects" do
    signed_in
    post "/supporting_documents", params: recibo_params
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    get "/supporting_documents"
    expect(response.body).to include("Mercado Silva")
    expect(response.body).not_to include("Padaria Central")
  end

  it "PATCH payee omits files and keeps blobs" do
    signed_in
    post "/supporting_documents", params: nota_params(photo: photo_jpg("danfe.jpg"))
    doc = SupportingDocument.last
    doc.xml.attach(io: StringIO.new("<nfe><vNF>100.00</vNF></nfe>"), filename: "autorizada.xml", content_type: "application/xml")

    patch "/supporting_documents/#{doc.id}", params: { payee: "Mercado Silva" }

    doc.reload
    expect(doc.photo).to be_attached
    expect(doc.xml).to be_attached
    expect(doc.photo.filename.to_s).to eq("danfe.jpg")
    expect(doc.xml.filename.to_s).to eq("autorizada.xml")
  end

  it "PATCH new photo replaces filename" do
    signed_in
    post "/supporting_documents", params: recibo_params(photo: photo_named("foto-antiga.jpg"))
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { photo: photo_named("foto-nova.jpg") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(SupportingDocument.find(id).photo.filename.to_s).to eq("foto-antiga.jpg")
  end

  it "POST observation pago em dinheiro appears" do
    signed_in

    post "/supporting_documents", params: recibo_params(observation: "pago em dinheiro")
    get "/supporting_documents"

    expect(response.body).to include("pago em dinheiro")
  end

  it "POST blank observation persists without pago em dinheiro" do
    signed_in

    post "/supporting_documents", params: recibo_params(observation: "")
    get "/supporting_documents"

    expect(SupportingDocument.count).to eq(1)
    expect(response.body).not_to include("pago em dinheiro")
  end

  it "POST amount 0 returns 422 Informe valor, data e favorecido" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params(amount: "0")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Informe valor, data e favorecido")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "POST blank payee returns 422 Informe valor, data e favorecido" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params(payee: "")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Informe valor, data e favorecido")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "POST invalid date returns 422 Informe valor, data e favorecido" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params(date: "not-a-date")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Informe valor, data e favorecido")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "POST kind other returns 422 Informe se e nota fiscal ou recibo" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params(kind: "invoice")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Informe se é nota fiscal ou recibo")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "POST photo of 10485761 bytes returns 422 max 10 MB" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params(photo: oversized_photo)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Cada arquivo pode ter no máximo 10 MB")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "POST photo .heic returns 422 A foto deve ser JPEG, PNG, WebP ou PDF" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params(photo: photo_heic)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("A foto deve ser JPEG, PNG, WebP ou PDF")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "POST xml .txt returns 422 O XML deve ser um arquivo .xml" do
    _account, organization = signed_in

    post "/supporting_documents", params: nota_params(xml: xml_txt)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("O XML deve ser um arquivo .xml")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "POST payee of 201 characters returns 422 Favorecido pode ter no maximo 200 caracteres" do
    _account, organization = signed_in

    post "/supporting_documents", params: recibo_params(payee: "a" * 201)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Favorecido pode ter no máximo 200 caracteres")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "PATCH supporting_document of another organization returns 404" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    sign_in_as(account, organization: org_b)
    post "/supporting_documents", params: recibo_params(payee: "Payee B")
    foreign_id = SupportingDocument.last.id

    sign_in_as(account, organization: org_a)
    patch "/supporting_documents/#{foreign_id}", params: { payee: "Hijacked" }

    expect(response).to have_http_status(:not_found)
    expect(SupportingDocument.find(foreign_id).payee).to eq("Payee B")
  end

  it "PATCH kind recibo on xml-only nota_fiscal returns 422 KIND_LOCKED" do
    signed_in
    post "/supporting_documents", params: nota_params(xml: authorized_xml)
    doc = SupportingDocument.last

    patch "/supporting_documents/#{doc.id}", params: { kind: "recibo" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq(SupportingDocument::KIND_LOCKED)
    doc.reload
    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.xml).to be_attached
  end

  it "PATCH kind recibo with photo returns 422 KIND_LOCKED and keeps xml" do
    signed_in
    post "/supporting_documents", params: nota_params(xml: authorized_xml)
    doc = SupportingDocument.last

    patch "/supporting_documents/#{doc.id}", params: { kind: "recibo", photo: photo_jpg("recibo-novo.jpg") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq(SupportingDocument::KIND_LOCKED)
    doc.reload
    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.xml).to be_attached
  end

  it "DELETE /supporting_documents/:id of a month document returns 422 and keeps the row" do
    account, organization = signed_in
    post "/supporting_documents", params: recibo_params(amount: "220,00")
    document = SupportingDocument.last
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    delete "/supporting_documents/#{document.id}"

    expect(response).to have_http_status(:unprocessable_content)
    expect(SupportingDocument.find(document.id)).to be_persisted
  end

  it "unauthenticated PATCH /supporting_documents/:id responds 302 to /login" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/supporting_documents", params: recibo_params
    id = SupportingDocument.last.id
    delete "/session"

    patch "/supporting_documents/#{id}", params: { payee: "Hacker" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(SupportingDocument.find(id).payee).to eq("Padaria Central")
  end

  it "GET /supporting_documents unmatched document does not include Casado em 2026-05" do
    signed_in
    post "/supporting_documents", params: recibo_params

    get "/supporting_documents"

    expect(response.body).to include("Padaria Central")
    expect(response.body).not_to include("Casado em 2026-05")
  end

  it "GET /supporting_documents after suggested 1:1 includes Casado em 2026-05" do
    account, organization = signed_in
    _month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    post "/supporting_documents", params: recibo_params(amount: "220,00")
    document = SupportingDocument.last

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ document.id ]
    }

    get "/supporting_documents"

    expect(response.body).to include("Casado em 2026-05")
    expect(response.body).to include("Padaria Central")
  end

  it "GET /supporting_documents after match includes Casado em 2026-05" do
    account, organization = signed_in
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    post "/supporting_documents", params: recibo_params(payee: "Padaria A", amount: "100,00", photo: photo_named("a.jpg"))
    post "/supporting_documents", params: recibo_params(payee: "Padaria B", amount: "120,00", photo: photo_named("b.jpg"))
    docs = organization.supporting_documents.order(:id)
    Match.confirm(month: month, payments: [ payment ], supporting_documents: docs.to_a)

    get "/supporting_documents"

    expect(response.body).to include("Casado em 2026-05")
    expect(response.body).to include("Padaria A")
    expect(response.body).to include("Padaria B")
  end

  it "PATCH payee on matched document keeps Casado" do
    account, organization = signed_in
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    post "/supporting_documents", params: recibo_params(amount: "220,00")
    document = SupportingDocument.last
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    patch "/supporting_documents/#{document.id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(Match.count).to eq(1)
    get "/months/2026-05"
    expect(response.body).to include("Casado")
    expect(payment.reload.match_id).to be_present
  end

  it "PATCH payee Outro on closed-month document returns 422 Mes fechado" do
    account, organization = signed_in
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    post "/supporting_documents", params: recibo_params(amount: "220,00")
    document = SupportingDocument.last
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
    month.update!(closed: true)

    patch "/supporting_documents/#{document.id}", params: { payee: "Outro" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(document.reload.payee).to eq("Padaria Central")
  end

  it "POST recibo while a month is closed persists no Month 302" do
    account, organization = signed_in
    month, _statement = plant_month(organization)
    month.update!(closed: true)

    post "/supporting_documents", params: recibo_params(payee: "Novo Recibo")

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    expect(SupportingDocument.find_by!(payee: "Novo Recibo").month_id).to be_nil
    expect(month.reload.closed?).to eq(true)
  end

  it "submitter documents page does not include another organization payee" do
    account, org_a = plant_submitter(email: "sub@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :submitter)
    sign_in_as(account, organization: org_b)
    post "/supporting_documents", params: recibo_params(payee: "Only Org B")

    sign_in_as(account, organization: org_a)
    get "/supporting_documents"

    expect(response.body).not_to include("Only Org B")
  end

  it "submitter GET /supporting_documents omits another Account payee" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(coord, organization: organization)
    post "/supporting_documents", params: recibo_params(payee: "Doc Alheio")
    sign_in_as(submitter, organization: organization)

    get "/supporting_documents"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Documentos de suporte")
    expect(response.body).not_to include("Doc Alheio")
  end

  it "submitter GET /supporting_documents with no own documents includes Nenhum documento" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    get "/supporting_documents"

    expect(response.body).to include("Nenhum documento")
  end

  it "submitter GET /supporting_documents matched document omits Casado em" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    post "/supporting_documents", params: recibo_params(amount: "220,00")
    document = SupportingDocument.last
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    get "/supporting_documents"

    expect(response.body).to include("Padaria Central")
    expect(response.body).not_to include("Casado em")
  end

  it "coordinator GET /supporting_documents includes submitter payee" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    post "/supporting_documents", params: recibo_params(payee: "Padaria Central")
    sign_in_as(coord, organization: organization)

    get "/supporting_documents"

    expect(response.body).to include("Padaria Central")
  end

  it "submitter POST recibo jpg persists Padaria Central Recibo and redirects" do
    _coord, organization = plant_coordinator
    account, _ = plant_submitter(organization: organization)
    sign_in_as(account, organization: organization)

    post "/supporting_documents", params: recibo_params(photo: photo_jpg("recibo.jpg"))

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    document = SupportingDocument.last
    expect(document.organization).to eq(organization)
    expect(document.account).to eq(account)
    expect(document.month_id).to be_nil
    expect(SupportingDocument.where(organization: organization).count).to eq(1)

    get "/supporting_documents"
    list = response.body[response.body.index("Sem mês")..]
    document_row = rows(list, "document").first
    expect(document_row.at_css('time[datetime="2026-05-11"]').text).to eq("11/05/2026")
    expect(document_row.text).to include("R$ 155,00", "Recibo", "Padaria Central")
  end

  it "submitter PATCH payee on own no-month document redirects" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    post "/supporting_documents", params: recibo_params
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    get "/supporting_documents"
    expect(response.body).to include("Mercado Silva")
    expect(response.body).not_to include("Padaria Central")
  end

  it "submitter PATCH payee on another Account document returns 404" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(coord, organization: organization)
    post "/supporting_documents", params: recibo_params
    id = SupportingDocument.last.id
    sign_in_as(submitter, organization: organization)

    patch "/supporting_documents/#{id}", params: { payee: "Hijacked" }

    expect(response).to have_http_status(:not_found)
    expect(SupportingDocument.find(id).payee).to eq("Padaria Central")
  end

  it "submitter PATCH payee on own month document returns 422" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    post "/supporting_documents", params: recibo_params(amount: "220,00")
    document = SupportingDocument.last
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    patch "/supporting_documents/#{document.id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(document.reload.payee).to eq("Padaria Central")
  end

  it "submitter DELETE own no-month document redirects and purges blobs" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    post "/supporting_documents", params: recibo_params(payee: "Padaria Central")
    document = SupportingDocument.last
    blob_id = document.photo.blob.id

    delete "/supporting_documents/#{document.id}"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    expect(SupportingDocument.find_by(id: document.id)).to be_nil
    expect(ActiveStorage::Blob.find_by(id: blob_id)).to be_nil
    get "/supporting_documents"
    expect(response.body).not_to include("Padaria Central")
  end

  it "submitter DELETE own month document returns 422" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    post "/supporting_documents", params: recibo_params(amount: "220,00")
    document = SupportingDocument.last
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    delete "/supporting_documents/#{document.id}"

    expect(response).to have_http_status(:unprocessable_content)
    expect(SupportingDocument.find(document.id)).to be_persisted
  end

  it "submitter DELETE another Account no-month document returns 404" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(coord, organization: organization)
    post "/supporting_documents", params: recibo_params(payee: "Doc Alheio")
    id = SupportingDocument.last.id
    sign_in_as(submitter, organization: organization)

    delete "/supporting_documents/#{id}"

    expect(response).to have_http_status(:not_found)
    expect(SupportingDocument.find(id)).to be_persisted
  end

  it "coordinator DELETE submitter no-month document redirects" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    post "/supporting_documents", params: recibo_params(payee: "Padaria Central")
    id = SupportingDocument.last.id
    sign_in_as(coord, organization: organization)

    delete "/supporting_documents/#{id}"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    expect(SupportingDocument.find_by(id: id)).to be_nil
  end

  it "PATCH payee reassigns Sugestao to Mercado Silva payment" do
    account, organization = signed_in
    _month, statement = plant_month(organization)
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_payment(statement, 22000, history: "Pix enviado — Mercado Silva")
    post "/supporting_documents", params: recibo_params(amount: "220,00", payee: "Padaria Central")
    document = SupportingDocument.last

    patch "/supporting_documents/#{document.id}", params: { payee: "Mercado Silva" }

    get "/months/2026-05"
    mercado = payment_status_html(response.body, history: "Pix enviado — Mercado Silva")
    padaria = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(mercado).to include("Sugestão")
    expect(padaria).not_to include("Sugestão")
  end

  it "POST authorized XML fills amount date payee chave and redirects" do
    signed_in

    post "/supporting_documents", params: { kind: "nota_fiscal", xml: authorized_xml }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    doc = SupportingDocument.last
    expect(doc.amount_cents).to eq(15500)
    expect(doc.document_on).to eq(Date.new(2026, 5, 11))
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.chave).to eq("43260511222333000181550010000000011123456781")

    get "/supporting_documents"
    expect(response.body).to include("R$ 155,00")
    expect(response.body).to include("11/05/2026")
    expect(response.body).to include("Padaria Central")
    expect(response.body).not_to include("ONG Destinataria")
    get "/supporting_documents/#{doc.id}/edit"
    expect(page_doc(response.body).at_css("#chave")["value"]).to eq("43260511222333000181550010000000011123456781")
  end

  it "PATCH amount on uploaded XML returns 422" do
    signed_in
    post "/supporting_documents", params: { kind: "nota_fiscal", xml: authorized_xml }
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { amount: "200,00" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Valor, data e favorecido vêm da nota e não podem ser alterados")
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
  end

  it "PATCH payee on uploaded XML returns 422" do
    signed_in
    post "/supporting_documents", params: { kind: "nota_fiscal", xml: authorized_xml }
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Valor, data e favorecido vêm da nota e não podem ser alterados")
    expect(SupportingDocument.find(id).payee).to eq("Padaria Central")
  end

  it "PATCH date on uploaded XML returns 422" do
    signed_in
    post "/supporting_documents", params: { kind: "nota_fiscal", xml: authorized_xml }
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { date: "2026-06-01" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Valor, data e favorecido vêm da nota e não podem ser alterados")
    expect(SupportingDocument.find(id).document_on).to eq(Date.new(2026, 5, 11))
  end

  it "PATCH observation on uploaded XML redirects" do
    signed_in
    post "/supporting_documents", params: { kind: "nota_fiscal", xml: authorized_xml }
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { observation: "pago em dinheiro" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    get "/supporting_documents"
    expect(response.body).to include("pago em dinheiro")
  end

  it "POST malformed XML returns 422" do
    _account, organization = signed_in

    post "/supporting_documents", params: nota_params(xml: xml_file("nota.xml", "<nfe><"))

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("O XML da nota fiscal não pôde ser lido")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "POST XML without ICMSTot vNF returns 422" do
    _account, organization = signed_in

    post "/supporting_documents", params: nota_params(xml: xml_with_vnf)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("O XML da nota fiscal não pôde ser lido")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "PATCH payee on pre-task XML blob redirects" do
    signed_in
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    doc = SupportingDocument.last
    doc.xml.attach(io: StringIO.new("<nfe><vNF>100.00</vNF></nfe>"), filename: "nota.xml", content_type: "application/xml")
    doc.update_column(:fields_origin, nil)

    patch "/supporting_documents/#{doc.id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(doc.reload.payee).to eq("Mercado Silva")
    expect(doc.amount_cents).to eq(15500)
  end

  it "POST recibo then PATCH payee Mercado Silva redirects" do
    signed_in
    post "/supporting_documents", params: recibo_params
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
  end

  it "POST typed nota_fiscal photo then PATCH payee redirects" do
    signed_in
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
  end

  it "POST chave with consulta XML fills fields and redirects" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta

    post "/supporting_documents", params: {
      kind: "nota_fiscal", photo: photo_jpg("danfe.jpg"), chave: nfe_chave
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    doc = SupportingDocument.last
    expect(doc.amount_cents).to eq(15500)
    expect(doc.document_on).to eq(Date.new(2026, 5, 11))
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.xml).to be_attached
    get "/supporting_documents"
    expect(response.body).to include("R$ 155,00")
    expect(response.body).to include("11/05/2026")
    expect(response.body).to include("Padaria Central")
    expect(response.body).to include(nfe_chave)
  end

  it "submitter POST chave with consulta XML persists and omits certificate" do
    coord, organization = plant_coordinator
    install_a1(organization)
    stub_xml_consulta
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    post "/supporting_documents", params: {
      kind: "nota_fiscal", photo: photo_jpg("danfe.jpg"), chave: nfe_chave
    }

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

  it "POST chave with consulta resumo locks fields without xml" do
    _account, organization = signed_in
    install_a1(organization)
    SefazConsulta.current.set(
      nfe_chave,
      SefazConsulta::Resumo.new(amount_cents: 15500, payee: "Padaria Central", document_on: Date.new(2026, 5, 11))
    )

    post "/supporting_documents", params: {
      kind: "nota_fiscal", photo: photo_jpg, chave: nfe_chave
    }

    doc = SupportingDocument.last
    expect(doc.amount_cents).to eq(15500)
    expect(doc.xml).not_to be_attached
    expect(doc.photo).to be_attached
    patch "/supporting_documents/#{doc.id}", params: { amount: "200,00" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Valor, data e favorecido vêm da nota e não podem ser alterados")
  end

  it "POST chave resumo without files returns 422 Envie a foto ou o XML" do
    _account, organization = signed_in
    install_a1(organization)
    SefazConsulta.current.set(
      nfe_chave,
      SefazConsulta::Resumo.new(amount_cents: 15500, payee: "Padaria Central", document_on: Date.new(2026, 5, 11))
    )

    post "/supporting_documents", params: { kind: "nota_fiscal", chave: nfe_chave }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Envie a foto ou o XML")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "POST chave consulta XML without files persists xml and redirects" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta

    post "/supporting_documents", params: { kind: "nota_fiscal", chave: nfe_chave }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.last.xml).to be_attached
    expect(SupportingDocument.last.amount_cents).to eq(15500)
  end

  it "POST chave without certificate stays typed and PATCH payee redirects" do
    signed_in

    post "/supporting_documents", params: nota_params(photo: photo_jpg, chave: nfe_chave)
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
  end

  it "POST chave with expired certificate stays typed and PATCH payee redirects" do
    _account, organization = signed_in
    travel_to Date.new(2026, 5, 11) do
      organization.install_sefaz_certificate(
        file: sefaz_pfx(not_after: Date.new(2026, 5, 11), name: "exp.pfx"),
        passphrase: "passphrase-secreta"
      )
    end
    travel_to Date.new(2026, 5, 12) do
      stub_xml_consulta
      post "/supporting_documents", params: nota_params(photo: photo_jpg, chave: nfe_chave)
      id = SupportingDocument.last.id
      patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }
      expect(response).to have_http_status(:found)
      expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
    end
  end

  it "POST chave after certificate removed stays typed and PATCH payee redirects" do
    _account, organization = signed_in
    install_a1(organization)
    organization.remove_sefaz_certificate
    stub_xml_consulta
    post "/supporting_documents", params: nota_params(photo: photo_jpg, chave: nfe_chave)
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
  end

  it "POST chave when consulta errors stays typed and PATCH payee redirects" do
    _account, organization = signed_in
    install_a1(organization)
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Error.new)
    post "/supporting_documents", params: nota_params(photo: photo_jpg, chave: nfe_chave)
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
  end

  it "POST chave when consulta errors without typed fields returns 422" do
    _account, organization = signed_in
    install_a1(organization)
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Error.new)

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg, chave: nfe_chave }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Informe valor, data e favorecido")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "POST chave when consulta not found or window-expired stays typed" do
    _account, organization = signed_in
    install_a1(organization)
    [ SefazConsulta::NotFound.new, SefazConsulta::WindowExpired.new ].each do |result|
      SefazConsulta.reset!
      SefazConsulta.current.set(nfe_chave, result)
      post "/supporting_documents", params: nota_params(photo: photo_named("n-#{result.class.name}.jpg"), chave: nfe_chave)
      id = SupportingDocument.last.id
      patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }
      expect(response).to have_http_status(:found)
      expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
    end
  end

  it "POST dotted chave persists 44 digits and XML fields" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta

    post "/supporting_documents", params: {
      kind: "nota_fiscal",
      photo: photo_jpg,
      chave: "4326.0511.2223.3300.0181.5500.1000.0000.0111.2345.6781"
    }

    expect(SupportingDocument.last.chave).to eq(nfe_chave)
    expect(SupportingDocument.last.xml).to be_attached
  end

  it "POST chave not 44 digits returns 422" do
    _account, organization = signed_in

    post "/supporting_documents", params: nota_params(photo: photo_jpg, chave: "123")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Informe a chave de acesso com 44 dígitos")
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
  end

  it "POST duplicate chave persists two SupportingDocuments" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta

    post "/supporting_documents", params: nota_params(photo: photo_named("a.jpg"), chave: nfe_chave)
    post "/supporting_documents", params: nota_params(photo: photo_named("b.jpg"), chave: nfe_chave)

    expect(SupportingDocument.where(organization: organization, chave: nfe_chave).count).to eq(2)
  end

  it "POST recibo with chave stores no chave and PATCH payee redirects" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta
    post "/supporting_documents", params: recibo_params(chave: nfe_chave)
    id = SupportingDocument.last.id

    expect(SupportingDocument.find(id).kind).to eq("recibo")
    expect(SupportingDocument.find(id).chave).to be_nil
    expect(SupportingDocument.find(id).xml).not_to be_attached
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }
    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
  end

  it "POST uploaded XML wins over consulta vNF 100.00" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")

    post "/supporting_documents", params: {
      kind: "nota_fiscal", xml: authorized_xml(vnf: "155.00"), chave: nfe_chave
    }

    expect(SupportingDocument.last.amount_cents).to eq(15500)
  end

  it "PATCH chave on uploaded XML keeps 15500" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00", emit: "Outro")
    post "/supporting_documents", params: {
      kind: "nota_fiscal", xml: authorized_xml(vnf: "155.00"), chave: nfe_chave
    }
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: {
      kind: "nota_fiscal", chave: nfe_chave, observation: "ok"
    }

    expect(response).to have_http_status(:found)
    doc = SupportingDocument.find(id)
    expect(doc.amount_cents).to eq(15500)
    expect(doc.fields_origin).to eq("uploaded_xml")
    expect(doc.payee).to eq("Padaria Central")
  end

  it "confirm identified SEFAZ on uploaded XML returns 422" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00", emit: "Outro")
    post "/supporting_documents", params: {
      kind: "nota_fiscal", xml: authorized_xml(vnf: "155.00"), chave: nfe_chave
    }
    id = SupportingDocument.last.id

    post "/supporting_documents/#{id}/sefaz_confirm"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Valor, data e favorecido vêm da nota e não podem ser alterados")
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
    expect(SupportingDocument.find(id).fields_origin).to eq("uploaded_xml")
  end

  it "PATCH kind recibo on locked nota returns 422 KIND_LOCKED" do
    signed_in
    post "/supporting_documents", params: { kind: "nota_fiscal", xml: authorized_xml }
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { kind: "recibo" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq(SupportingDocument::KIND_LOCKED)
    doc = SupportingDocument.find(id)
    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.xml).to be_attached
  end

  it "PATCH kind nota_fiscal on recibo returns 422 KIND_LOCKED" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00", emit: "Mercado Silva", dhemi: "2026-05-12T10:00:00-03:00")
    post "/supporting_documents", params: recibo_params
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { kind: "nota_fiscal", chave: nfe_chave }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq(SupportingDocument::KIND_LOCKED)
    expect(SupportingDocument.find(id).kind).to eq("recibo")
  end

  it "PATCH chave on typed nota keeps 15500 and includes Usar dados da SEFAZ" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
    get "/supporting_documents/#{id}/edit"
    expect(response.body).to include("Usar dados da SEFAZ")
  end

  it "PATCH observation on pending chave still includes Usar dados da SEFAZ" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }

    patch "/supporting_documents/#{id}", params: { observation: "ok" }

    expect(response).to have_http_status(:found)
    get "/supporting_documents/#{id}/edit"
    expect(response.body).to include("Usar dados da SEFAZ")
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
  end

  it "confirm identified SEFAZ persists 10000 and redirects" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }

    post "/supporting_documents/#{id}/sefaz_confirm"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    get "/supporting_documents"
    expect(response.body).to include("R$ 100,00")
    expect(response.body).not_to include("R$ 155,00")
    expect(SupportingDocument.find(id).amount_cents).to eq(10000)
  end

  it "confirm identified SEFAZ from resumo persists 10000 and redirects" do
    _account, organization = signed_in
    install_a1(organization)
    stub_resumo_consulta(amount_cents: 10000, payee: "Mercado Silva", document_on: Date.new(2026, 5, 12))
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }

    post "/supporting_documents/#{id}/sefaz_confirm"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    get "/supporting_documents"
    expect(response.body).to include("R$ 100,00")
    expect(response.body).not_to include("R$ 155,00")
    doc = SupportingDocument.find(id)
    expect(doc.amount_cents).to eq(10000)
    expect(doc.payee).to eq("Mercado Silva")
    expect(doc.document_on).to eq(Date.new(2026, 5, 12))
    expect(doc.xml).not_to be_attached
  end

  it "confirm identified SEFAZ with blank chave returns 422" do
    signed_in
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    id = SupportingDocument.last.id

    post "/supporting_documents/#{id}/sefaz_confirm"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Não foi possível consultar a SEFAZ")
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
  end

  it "confirm identified SEFAZ when xml cannot be parsed returns 422" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Xml.new("<nfe>sem infNFe</nfe>"))

    post "/supporting_documents/#{id}/sefaz_confirm"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Não foi possível consultar a SEFAZ")
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }
    expect(response).to have_http_status(:found)
  end

  it "POST chave with stored certificate and blank wrap key stays typed" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")

    with_env("SEFAZ_WRAP_KEY" => nil) do
      post "/supporting_documents", params: nota_params(photo: photo_jpg, chave: nfe_chave)
    end

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.last.amount_cents).to eq(15500)
    expect(SupportingDocument.last.xml).not_to be_attached
    patch "/supporting_documents/#{SupportingDocument.last.id}", params: { payee: "Mercado Silva" }
    expect(response).to have_http_status(:found)
  end

  it "confirm identified SEFAZ when consulta errors returns 422" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Error.new)

    post "/supporting_documents/#{id}/sefaz_confirm"

    expect(response).to have_http_status(:unprocessable_content)
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }
    expect(response).to have_http_status(:found)
  end

  it "PATCH chave without certificate stores chave and omits Usar dados da SEFAZ" do
    signed_in
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }

    expect(SupportingDocument.find(id).chave).to eq(nfe_chave)
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
    get "/supporting_documents"
    expect(response.body).not_to include("Usar dados da SEFAZ")
  end

  it "confirm identified SEFAZ on already identified redirects unchanged" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg, chave: nfe_chave }
    id = SupportingDocument.last.id
    amount = SupportingDocument.find(id).amount_cents

    post "/supporting_documents/#{id}/sefaz_confirm"

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).amount_cents).to eq(amount)
    expect(SupportingDocument.find(id).payee).to eq("Padaria Central")
  end

  it "PATCH chave on closed month returns 422 Mes fechado" do
    _account, organization = signed_in
    post "/supporting_documents", params: nota_params(photo: photo_jpg, amount: "220,00")
    document = SupportingDocument.last
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
    month.update!(closed: true)

    patch "/supporting_documents/#{document.id}", params: { chave: nfe_chave }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(document.reload.chave).to be_nil
  end

  it "submitter PATCH chave on own no-month document redirects" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).chave).to eq(nfe_chave)
  end

  it "submitter PATCH chave on another Account document returns 404" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(coord, organization: organization)
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    id = SupportingDocument.last.id
    sign_in_as(submitter, organization: organization)

    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }

    expect(response).to have_http_status(:not_found)
    expect(SupportingDocument.find(id).chave).to be_nil
  end

  it "submitter PATCH chave on month document returns 422" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    post "/supporting_documents", params: nota_params(photo: photo_jpg, amount: "220,00")
    document = SupportingDocument.last
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    patch "/supporting_documents/#{document.id}", params: { chave: nfe_chave }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Documento já pertence a um mês")
    expect(document.reload.chave).to be_nil
  end

  it "install A1 after typed chave does not retro-consult" do
    _account, organization = signed_in
    post "/supporting_documents", params: nota_params(photo: photo_jpg, chave: nfe_chave)
    id = SupportingDocument.last.id
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")

    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
  end

  it "DELETE certificate leaves identified lock on amount PATCH" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg, chave: nfe_chave }
    id = SupportingDocument.last.id
    delete "/sefaz_certificate"

    patch "/supporting_documents/#{id}", params: { amount: "200,00" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
  end

  it "expired certificate leaves identified lock on amount PATCH" do
    _account, organization = signed_in
    travel_to Date.new(2026, 5, 11) do
      organization.install_sefaz_certificate(
        file: sefaz_pfx(not_after: Date.new(2026, 5, 11), name: "exp.pfx"),
        passphrase: "passphrase-secreta"
      )
      stub_xml_consulta
      post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg, chave: nfe_chave }
    end
    id = SupportingDocument.last.id
    travel_to Date.new(2026, 5, 12) do
      patch "/supporting_documents/#{id}", params: { amount: "200,00" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(SupportingDocument.find(id).amount_cents).to eq(15500)
    end
  end

  it "GET /supporting_documents after matching unmatched-in-package Padaria includes Casado em 2026-05" do
    account, organization = signed_in
    ready_to_close!(organization)
    month, statement = plant_month(organization)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    post "/months/2026-05/close", params: { supporting_document_ids: [ document.id ] }
    post "/months/2026-05/reopen"
    payment = plant_payment(statement, 15500)
    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ document.id ]
    }

    get "/supporting_documents"

    expect(response.body).to include("Casado em 2026-05")
    expect(response.body).not_to include("Sem casamento em 2026-05")
    expect(document.reload.month_id).to eq(month.id)
  end

  it "GET /supporting_documents after unmatched close includes Sem casamento em 2026-05" do
    account, organization = signed_in
    ready_to_close!(organization)
    plant_month(organization)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    post "/months/2026-05/close", params: { supporting_document_ids: [ document.id ] }

    get "/supporting_documents"

    expect(response.body).to include("Sem casamento em 2026-05")
    expect(response.body).not_to include("Casado em 2026-05")
  end

  it "PATCH payee while unmatched-in-package of a closed month returns 422 Mes fechado" do
    account, organization = signed_in
    ready_to_close!(organization)
    plant_month(organization)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    post "/months/2026-05/close", params: { supporting_document_ids: [ document.id ] }

    patch "/supporting_documents/#{document.id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(document.reload.payee).to eq("Padaria Central")
  end

  it "PATCH payee of unmatched-in-package Padaria while open persists Mercado Silva" do
    account, organization = signed_in
    ready_to_close!(organization)
    plant_month(organization)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    post "/months/2026-05/close", params: { supporting_document_ids: [ document.id ] }
    post "/months/2026-05/reopen"

    patch "/supporting_documents/#{document.id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(document.reload.payee).to eq("Mercado Silva")
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
    expect(response.body).to include('id="chave"')
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

  def signed_submitter
    _coord, organization = plant_coordinator
    account, _ = plant_submitter(organization: organization)
    sign_in_as(account, organization: organization)
    [ account, organization ]
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
    signed_in

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

    get "/supporting_documents"
    expect(insert_form(response.body).at_css("#kind")["disabled"]).to be_present

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
    signed_in

    get "/supporting_documents"

    kind = insert_form(response.body).at_css("select#kind")
    expect(html_visible?(kind)).to eq(false)
    expect(kind.at_css('option[value="nota_fiscal"]').text.strip).to eq("Nota fiscal")
    expect(kind.at_css('option[value="recibo"]').text.strip).to eq("Recibo")
  end

  it "GET insert empty kind hides chave and xml" do
    signed_in

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
    signed_in

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
