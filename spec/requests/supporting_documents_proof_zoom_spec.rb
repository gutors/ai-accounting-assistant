require "rails_helper"

RSpec.describe "Supporting document proof zoom", type: :request do
  CHAVE = "35240612345678000190550010000012341000012340"
  GROUPED = "3524 0612 3456 7800 0190 5500 1000 0012 3410 0001 2340"

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

  def identify_stream_doc(body)
    html = turbo_stream_nodes(body).map(&:inner_html).join
    Nokogiri::HTML(html)
  end

  def plant_chave_document
    signed_in
    post "/supporting_documents", params: {
      kind: "nota_fiscal", amount: "155,00", date: "2026-05-11", payee: "Padaria Central",
      photo: photo_jpg, chave: CHAVE
    }
    SupportingDocument.last
  end

  it "GET edit PDF has no Ampliar and embed toolbar=1" do
    account, organization = signed_in
    document = SupportingDocument.insert(
      organization: organization, account: account, kind: "recibo",
      amount: "155,00", date: "2026-05-11", payee: "Padaria Central",
      photo: pdf_upload("nota.pdf", pngs_to_pdf(ocr_png("blank.png")))
    )

    get "/supporting_documents/#{document.id}/edit"

    expect(response).to have_http_status(:ok)
    proof = page_doc(response.body).at_css("[data-edit=proof]")
    expect(proof.at_css("[aria-label=Ampliar]")).to be_nil
    expect(proof.at_css("[aria-label=Reduzir]")).to be_nil
    expect(proof.at_css("embed[type='application/pdf']")["src"]).to include("#toolbar=1")
  end

  it "GET edit XML-only has no Ampliar" do
    signed_in
    post "/supporting_documents", params: {
      kind: "nota_fiscal", amount: "155,00", date: "2026-05-11", payee: "Padaria Central",
      xml: authorized_xml
    }
    id = SupportingDocument.last.id

    get "/supporting_documents/#{id}/edit"

    expect(response).to have_http_status(:ok)
    proof = page_doc(response.body).at_css("[data-edit=proof]")
    expect(proof.at_css("[aria-label=Ampliar]")).to be_nil
    expect(proof.at_css("[aria-label=Reduzir]")).to be_nil
  end

  it "GET supporting_documents omits grouped chave from Sem mes" do
    document = plant_chave_document

    get "/supporting_documents"

    expect(response).to have_http_status(:ok)
    sem = page_doc(response.body).at_css("#sem-mes")
    expect(sem.at_css("[data-chave]")).to be_nil
    expect(sem.text).not_to include(GROUPED)
    expect(row(response.body, "document", document_id: document.id)).to be_present
  end

  it "GET edit keeps raw chave digits" do
    document = plant_chave_document

    get "/supporting_documents/#{document.id}/edit"

    expect(response).to have_http_status(:ok)
    expect(page_doc(response.body).at_css("input#chave")["value"]).to eq(CHAVE)
  end

  it "GET supporting_documents Sem mes still shows payee amount kind filename" do
    plant_chave_document

    get "/supporting_documents"

    sem = page_doc(response.body).at_css("#sem-mes")
    expect(sem.text).to include("Padaria Central")
    expect(sem.text).to include("R$ 155,00")
    expect(sem.text).to include("Nota fiscal")
    expect(sem.text).to include("recibo.jpg")
  end

  it "POST identify preview still shows grouped chave" do
    signed_submitter

    post "/supporting_documents/identify",
      params: { file: authorized_xml("proc-nfe.xml", chave: CHAVE) },
      headers: turbo_stream_accept

    expect(response).to have_http_status(:ok)
    doc = identify_stream_doc(response.body)
    preview = doc.at_css("#identify-preview")
    expect(preview.text).to include(GROUPED)
  end
end
