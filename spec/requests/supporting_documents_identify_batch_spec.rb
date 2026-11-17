require "rails_helper"

RSpec.describe "Supporting document identify_batch", type: :request do
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

  it "POST identify_batch two authorized XMLs fills items without persisting" do
    signed_in

    post "/supporting_documents/identify_batch", params: {
      files: [
        authorized_xml("proc-nfe-padaria.xml", vnf: "155.00", emit: "Padaria Central", dhemi: "2026-05-11T10:00:00-03:00"),
        authorized_xml("proc-nfe-farmacia.xml", vnf: "89.40", emit: "Farmácia São José")
      ]
    }

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:ok)
    items = response.parsed_body.fetch("items")
    expect(items.size).to eq(2)
    expect(items[0]["ok"]).to eq(true)
    expect(items[0]["payee"]).to eq("Padaria Central")
    expect(items[0]["amount"]).to eq("155,00")
    expect(items[0]["kind"]).to eq("nota_fiscal")
    expect(items[0]["locked"]).to eq(true)
    expect(items[0]["origin"]).to eq("XML autorizado")
    expect(items[0]["arquivo"]).to eq("XML")
    expect(items[1]["payee"]).to eq("Farmácia São José")
    expect(items[1]["amount"]).to eq("89,40")
  end

  it "POST identify_batch empty.jpg is recibo typed empty" do
    signed_in

    post "/supporting_documents/identify_batch", params: { files: [ photo_jpg("empty.jpg") ] }

    expect(response).to have_http_status(:ok)
    item = response.parsed_body.fetch("items").fetch(0)
    expect(item["ok"]).to eq(true)
    expect(item["kind"]).to eq("recibo")
    expect(item["locked"]).to eq(false)
    expect(item["origin"]).to eq("Digitado")
    expect(item["arquivo"]).to eq("Foto")
    expect(item["amount"]).to eq("")
    expect(item["date"]).to eq("")
    expect(item["payee"]).to eq("")
  end

  it "POST identify_batch mixed XML keeps Padaria and unreadable error" do
    signed_in

    post "/supporting_documents/identify_batch", params: {
      files: [
        authorized_xml("proc-nfe-padaria.xml", emit: "Padaria Central"),
        xml_file("nota.xml", "<nfe/>")
      ]
    }

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:ok)
    items = response.parsed_body.fetch("items")
    expect(items[0]["ok"]).to eq(true)
    expect(items[0]["payee"]).to eq("Padaria Central")
    expect(items[1]["ok"]).to eq(false)
    expect(items[1]["error"]).to eq("O XML da nota fiscal não pôde ser lido")
  end

  it "POST identify_batch missing or empty files is 422 Envie os arquivos" do
    signed_in

    post "/supporting_documents/identify_batch"
    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to eq({ "error" => "Envie os arquivos" })

    post "/supporting_documents/identify_batch", params: { files: [] }
    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to eq({ "error" => "Envie os arquivos" })
  end

  it "POST identify_batch 31 files is 422 No maximo 30" do
    signed_in

    post "/supporting_documents/identify_batch", params: {
      files: Array.new(31) { |index| photo_jpg("f#{index}.jpg") }
    }

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to eq({ "error" => "No máximo 30 arquivos neste lote" })
  end

  it "unauthenticated POST identify_batch responds 302 to /login" do
    post "/supporting_documents/identify_batch", params: { files: [ photo_jpg("empty.jpg") ] }

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "submitter POST identify_batch persists none and 404" do
    signed_submitter

    post "/supporting_documents/identify_batch", params: { files: [ photo_jpg("empty.jpg") ] }

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:not_found)
  end

  it "POST identify_batch photo fields origin Lido da foto" do
    signed_in
    stub_photo_fields("danfe.jpg")

    post "/supporting_documents/identify_batch", params: { files: [ photo_jpg("danfe.jpg") ] }

    expect(response).to have_http_status(:ok)
    item = response.parsed_body.fetch("items").fetch(0)
    expect(item["ok"]).to eq(true)
    expect(item["origin"]).to eq("Lido da foto")
    expect(item["locked"]).to eq(false)
  end

  it "POST identify_batch NFC-e QR origin Consulta NFC-e" do
    signed_in
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)

    post "/supporting_documents/identify_batch", params: { files: [ photo_jpg("nfce.jpg") ] }

    expect(response).to have_http_status(:ok)
    item = response.parsed_body.fetch("items").fetch(0)
    expect(item["ok"]).to eq(true)
    expect(item["origin"]).to eq("Consulta NFC-e")
  end

  it "POST identify_batch without focus responds 302 to /login" do
    account, organization = plant_coordinator(email: "coord@example.com")
    other = Account.create!(email: "other@example.com", google_uid: "uid-other")
    Access.create!(account: other, organization: organization, kind: :coordinator)
    sign_in_as(account, organization: organization)
    Access.where(account: account).delete_all

    post "/supporting_documents/identify_batch", params: { files: [ photo_jpg("empty.jpg") ] }

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "POST identify_batch keeps files order b.jpg then a.jpg" do
    signed_in

    post "/supporting_documents/identify_batch", params: {
      files: [ photo_jpg("b.jpg"), photo_jpg("a.jpg") ]
    }

    expect(response).to have_http_status(:ok)
    items = response.parsed_body.fetch("items")
    expect(items[0]["filename"]).to eq("b.jpg")
    expect(items[1]["filename"]).to eq("a.jpg")
  end
end
