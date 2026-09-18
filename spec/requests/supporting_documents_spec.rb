require "rails_helper"

RSpec.describe "Supporting documents", type: :request do
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
    expect(list).to match(%r{<time datetime="2026-05-11">11/05/2026</time>\s*R\$ 155,00\s*Recibo\s*Padaria Central}m)
    expect(list).to include("recibo.jpg")
  end

  it "POST recibo belongs to inserting Account and creates no Month" do
    account, _organization = signed_in

    expect do
      post "/supporting_documents", params: recibo_params
    end.not_to change(Month, :count)

    expect(SupportingDocument.last.account).to eq(account)
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
    expect(list).to match(%r{<time datetime="2026-05-11">11/05/2026</time>\s*R\$ 155,00\s*Nota fiscal\s*Padaria Central}m)
    expect(list).to include("danfe.jpg")
  end

  it "POST nota_fiscal xml persists xml filename" do
    signed_in

    post "/supporting_documents", params: nota_params(xml: xml_file("autorizada.xml"))

    expect(response).to have_http_status(:found)
    doc = SupportingDocument.last
    expect(doc.xml).to be_attached
    expect(doc.photo).not_to be_attached

    get "/supporting_documents"
    expect(response.body).to include("autorizada.xml")
  end

  it "POST nota_fiscal photo and xml persists both blobs" do
    signed_in

    post "/supporting_documents", params: nota_params(photo: photo_jpg, xml: xml_file)

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

  it "POST nota_fiscal xml vNF 100.00 persists amount 15500" do
    signed_in

    post "/supporting_documents", params: nota_params(amount: "155,00", xml: xml_with_vnf)

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
    post "/supporting_documents", params: nota_params(photo: photo_jpg("danfe.jpg"), xml: xml_file("autorizada.xml"))
    doc = SupportingDocument.last

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
    post "/supporting_documents", params: nota_params(xml: xml_file)
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
    post "/supporting_documents", params: nota_params(xml: xml_file)
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
    expect(list).to match(%r{<time datetime="2026-05-11">11/05/2026</time>\s*R\$ 155,00\s*Recibo\s*Padaria Central}m)
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
end
