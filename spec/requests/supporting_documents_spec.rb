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
    org_b = Organization.create!(name: "B")
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

  # Ledger arrangement (visual-identity C44, C45, C47, C48)

  def editar_details(document_row)
    details = document_row.css("details").select { |node| node.at_css("summary")&.text&.strip == "Editar" }
    expect(details.size).to eq(1)
    details.first
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
    edit_form = document_row.css("form").find { |node| node["action"] == "/supporting_documents/#{document.id}" && node.at_css('input[name="_method"][value="patch"]') }
    expect(edit_form).not_to be_nil
    expect(edit_form.ancestors.include?(editar_details(document_row))).to eq(true)
  end

  it "Excluir sits inside Editar" do
    account, organization = signed_in
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents"

    document_row = row(response.body, "document", document_id: document.id)
    excluir = document_row.css("button").find { |button| button.text.strip == "Excluir" }
    expect(excluir).not_to be_nil
    expect(excluir.ancestors.include?(editar_details(document_row))).to eq(true)
  end

  it "Usar dados da SEFAZ stays outside Editar" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00")
    post "/supporting_documents", params: nota_params(photo: photo_jpg)
    id = SupportingDocument.last.id
    patch "/supporting_documents/#{id}", params: { chave: nfe_chave }
    expect(SupportingDocument.find(id).sefaz_confirm_pending?).to eq(true)

    get "/supporting_documents"

    document_row = row(response.body, "document", document_id: id)
    sefaz = document_row.css("button").find { |button| button.text.strip == "Usar dados da SEFAZ" }
    expect(sefaz).not_to be_nil
    expect(sefaz.ancestors("details")).to be_empty
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
    expect(document_row.at_css('input[name="chave"]')["value"]).to eq(chave)
  end

  it "document error renders as a data-notice error alert" do
    signed_in

    post "/supporting_documents", params: {
      kind: "recibo", amount: "155,00", date: "2026-05-11", payee: "Padaria Central"
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Envie a foto do recibo")
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

    post "/supporting_documents", params: recibo_params(xml: xml_file)

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

    expect(response).to have_http_status(:found)
    doc = SupportingDocument.last
    expect(doc.photo).to be_attached
    expect(doc.xml).to be_attached
  end

  it "POST nota_fiscal without files returns 422 Envie a foto e/ou o XML" do
    _account, organization = signed_in

    post "/supporting_documents", params: nota_params

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Envie a foto e/ou o XML")
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

    get "/supporting_documents"
    expect(response.body).to include("foto-nova.jpg")
    expect(response.body).not_to include("foto-antiga.jpg")
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
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    sign_in_as(account, organization: org_b)
    post "/supporting_documents", params: recibo_params(payee: "Payee B")
    foreign_id = SupportingDocument.last.id

    sign_in_as(account, organization: org_a)
    patch "/supporting_documents/#{foreign_id}", params: { payee: "Hijacked" }

    expect(response).to have_http_status(:not_found)
    expect(SupportingDocument.find(foreign_id).payee).to eq("Payee B")
  end

  it "PATCH kind recibo on xml-only nota_fiscal without photo returns 422 Envie a foto do recibo" do
    signed_in
    post "/supporting_documents", params: nota_params(xml: authorized_xml)
    doc = SupportingDocument.last

    patch "/supporting_documents/#{doc.id}", params: { kind: "recibo" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Envie a foto do recibo")
    doc.reload
    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.xml).to be_attached
  end

  it "PATCH kind recibo with photo purges xml" do
    signed_in
    post "/supporting_documents", params: nota_params(xml: authorized_xml)
    doc = SupportingDocument.last

    patch "/supporting_documents/#{doc.id}", params: { kind: "recibo", photo: photo_jpg("recibo-novo.jpg") }

    doc.reload
    expect(doc.kind).to eq("recibo")
    expect(doc.photo).to be_attached
    expect(doc.photo.filename.to_s).to eq("recibo-novo.jpg")
    expect(doc.xml).not_to be_attached
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
    org_b = Organization.create!(name: "B")
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
    expect(response.body).to include("43260511222333000181550010000000011123456781")
    expect(response.body).not_to include("ONG Destinataria")
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

  it "POST chave resumo without files returns 422 Envie a foto e/ou o XML" do
    _account, organization = signed_in
    install_a1(organization)
    SefazConsulta.current.set(
      nfe_chave,
      SefazConsulta::Resumo.new(amount_cents: 15500, payee: "Padaria Central", document_on: Date.new(2026, 5, 11))
    )

    post "/supporting_documents", params: { kind: "nota_fiscal", chave: nfe_chave }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Envie a foto e/ou o XML")
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
      kind: "nota_fiscal", photo: photo_jpg, xml: authorized_xml(vnf: "155.00"), chave: nfe_chave
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
      kind: "nota_fiscal", photo: photo_jpg, xml: authorized_xml(vnf: "155.00"), chave: nfe_chave
    }
    id = SupportingDocument.last.id

    post "/supporting_documents/#{id}/sefaz_confirm"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Valor, data e favorecido vêm da nota e não podem ser alterados")
    expect(SupportingDocument.find(id).amount_cents).to eq(15500)
    expect(SupportingDocument.find(id).fields_origin).to eq("uploaded_xml")
  end

  it "PATCH kind recibo on locked nota discards xml chave and unlocks" do
    signed_in
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg, xml: authorized_xml }
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { kind: "recibo" }

    doc = SupportingDocument.find(id)
    expect(doc.kind).to eq("recibo")
    expect(doc.xml).not_to be_attached
    expect(doc.chave).to be_nil
    expect(doc.amount_cents).to eq(15500)
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }
    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
  end

  it "PATCH kind nota_fiscal on recibo fires consulta and locks" do
    _account, organization = signed_in
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00", emit: "Mercado Silva", dhemi: "2026-05-12T10:00:00-03:00")
    post "/supporting_documents", params: recibo_params
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { kind: "nota_fiscal", chave: nfe_chave }

    doc = SupportingDocument.find(id)
    expect(doc.amount_cents).to eq(10000)
    expect(doc.payee).to eq("Mercado Silva")
    expect(doc.document_on).to eq(Date.new(2026, 5, 12))
    expect(doc.xml).to be_attached
    patch "/supporting_documents/#{id}", params: { amount: "200,00" }
    expect(response).to have_http_status(:unprocessable_content)
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
    get "/supporting_documents"
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
    get "/supporting_documents"
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

    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("danfe.jpg"), xml: authorized_xml }

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
    expect(response.body).to include(nfce_chave)
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
      kind: "nota_fiscal", photo: photo_jpg("danfe.jpg"), xml: xml_file("nota.xml", "<nfe><")
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
    get "/supporting_documents"
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
    get "/supporting_documents"
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

  it "PATCH kind nota_fiscal on recibo reads existing photo chave" do
    _account, organization = signed_in
    stub_photo_symbols("recibo.jpg", chave: nfe_chave)
    install_a1(organization)
    stub_xml_consulta(vnf: "100.00", emit: "Mercado Silva", dhemi: "2026-05-12T10:00:00-03:00")
    post "/supporting_documents", params: recibo_params
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { kind: "nota_fiscal" }

    doc = SupportingDocument.find(id)
    expect(doc.amount_cents).to eq(10000)
    expect(doc.payee).to eq("Mercado Silva")
    expect(doc.document_on).to eq(Date.new(2026, 5, 12))
    expect(doc.xml).to be_attached
    patch "/supporting_documents/#{id}", params: { amount: "200,00" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "PATCH kind recibo on photo-filled nota drops chave and unlocks" do
    signed_in
    stub_photo_fields("fields.jpg")
    stub_photo_symbols("fields.jpg", chave: nfe_chave)
    post "/supporting_documents", params: { kind: "nota_fiscal", photo: photo_jpg("fields.jpg") }
    id = SupportingDocument.last.id

    patch "/supporting_documents/#{id}", params: { kind: "recibo" }

    doc = SupportingDocument.find(id)
    expect(doc.kind).to eq("recibo")
    expect(doc.chave).to be_nil
    expect(doc.amount_cents).to eq(15500)
    patch "/supporting_documents/#{id}", params: { payee: "Mercado Silva" }
    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(id).payee).to eq("Mercado Silva")
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
    expect(response.body).to include('id="photo"')
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
end
