require "rails_helper"

RSpec.describe "Supporting document recibo PDF", type: :request do
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

  def origin_copy(doc, field)
    doc.at_css(%([data-origin="#{field}"]))&.text&.strip
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

  it "POST identify Padaria recibo PDF fills book Lido da foto" do
    signed_in
    stub_recibo_fields("padaria-recibo.pdf")

    post "/supporting_documents/identify", params: {
      file: pdf_upload("padaria-recibo.pdf", text_pdf(padaria_recibo_text))
    }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:ok)
    doc = identify_stream_doc(response.body)
    expect(doc.at_css("#arquivo")["value"]).to eq("Foto")
    expect(selected_option_value(doc.at_css("select#kind"))).to eq("recibo")
    expect(doc.at_css("select#kind")["disabled"]).to be_present
    expect(html_visible?(doc.at_css("#chave"))).to eq(false)
    expect(doc.at_css("#amount")["value"]).to eq("155,00")
    expect(doc.at_css("#date")["value"]).to eq("2026-06-15")
    expect(doc.at_css("#payee")["value"]).to eq("Padaria Central")
    %w[amount date payee].each do |field|
      expect(origin_copy(doc, field)).to eq("Lido da foto")
      expect(doc.at_css("##{field}")["disabled"]).to be_nil
    end
  end

  it "submitter POST identify Padaria recibo PDF fills book Lido da foto" do
    signed_submitter
    stub_recibo_fields("padaria-recibo.pdf")

    post "/supporting_documents/identify", params: {
      file: pdf_upload("padaria-recibo.pdf", text_pdf(padaria_recibo_text))
    }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:ok)
    doc = identify_stream_doc(response.body)
    expect(doc.at_css("#amount")["value"]).to eq("155,00")
    expect(doc.at_css("#date")["value"]).to eq("2026-06-15")
    expect(doc.at_css("#payee")["value"]).to eq("Padaria Central")
    %w[amount date payee].each do |field|
      expect(origin_copy(doc, field)).to eq("Lido da foto")
    end
  end

  it "POST identify JPEG recibo ignores PhotoFields and stays Digitado" do
    signed_in
    PhotoFields.current.set("recibo.jpg", amount_cents: nil, document_on: nil, payee: "Mercado Silva")

    post "/supporting_documents/identify", params: { file: photo_jpg("recibo.jpg") }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:ok)
    doc = identify_stream_doc(response.body)
    expect(selected_option_value(doc.at_css("select#kind"))).to eq("recibo")
    expect(doc.at_css("#amount")["value"].to_s).to eq("")
    expect(doc.at_css("#date")["value"].to_s).to eq("")
    expect(doc.at_css("#payee")["value"].to_s).to eq("")
    %w[amount date payee].each do |field|
      expect(origin_copy(doc, field)).to eq("Digitado")
    end
  end

  it "POST identify app receipt PDF is recibo typed empty" do
    signed_in
    ReciboFields.current.miss("uber-recibo.pdf")

    post "/supporting_documents/identify", params: {
      file: pdf_upload("uber-recibo.pdf", text_pdf("Aqui está o recibo da sua entrega\nTotal\nPreço da viagem"))
    }, headers: turbo_stream_accept

    expect(SupportingDocument.count).to eq(0)
    expect(response).to have_http_status(:ok)
    doc = identify_stream_doc(response.body)
    expect(selected_option_value(doc.at_css("select#kind"))).to eq("recibo")
    expect(doc.at_css("#amount")["value"].to_s).to eq("")
    expect(doc.at_css("#date")["value"].to_s).to eq("")
    expect(doc.at_css("#payee")["value"].to_s).to eq("")
    %w[amount date payee].each do |field|
      expect(origin_copy(doc, field)).to eq("Digitado")
    end
  end

  it "POST Padaria recibo PDF persists photo origin 15500" do
    _account, organization = signed_in
    stub_recibo_fields("padaria-recibo.pdf")

    post "/supporting_documents", params: { photo: pdf_upload("padaria-recibo.pdf", text_pdf(padaria_recibo_text)) }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    doc = SupportingDocument.find_by!(organization: organization)
    expect(doc.kind).to eq("recibo")
    expect(doc.amount_cents).to eq(15500)
    expect(doc.document_on).to eq(Date.new(2026, 6, 15))
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.fields_origin).to eq("photo")
    expect(doc.chave).to be_nil
    expect(doc.xml).not_to be_attached
    get "/supporting_documents"
    expect(response.body).to include("R$ 155,00")
    expect(response.body).to include("15/06/2026")
    expect(response.body).to include("Padaria Central")
  end

  it "GET edit Padaria recibo PDF origins Lido da foto then PATCH payee" do
    account, organization = signed_in
    stub_recibo_fields("padaria-recibo.pdf")
    document = SupportingDocument.insert(
      organization: organization, account: account, kind: "recibo",
      amount: nil, date: nil, payee: nil,
      photo: pdf_upload("padaria-recibo.pdf", text_pdf(padaria_recibo_text)), xml: nil
    )
    expect(document.fields_origin).to eq("photo")

    get "/supporting_documents/#{document.id}/edit"

    page = page_doc(response.body)
    %w[amount date payee].each do |field|
      expect(page.at_css("##{field}")["disabled"]).to be_nil
      expect(origin_copy(page, field)).to eq("Lido da foto")
    end

    patch "/supporting_documents/#{document.id}", params: { payee: "Mercado Silva" }

    expect(response).to have_http_status(:found)
    expect(SupportingDocument.find(document.id).payee).to eq("Mercado Silva")
  end

  it "POST Padaria recibo PDF wins over typed payee" do
    _account, organization = signed_in
    stub_recibo_fields("padaria-recibo.pdf")

    post "/supporting_documents", params: {
      kind: "recibo",
      photo: pdf_upload("padaria-recibo.pdf", text_pdf(padaria_recibo_text)),
      amount: "155,00",
      date: "2026-06-15",
      payee: "Mercado Silva"
    }

    doc = SupportingDocument.find_by!(organization: organization)
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.fields_origin).to eq("photo")
  end

  it "POST incomplete recibo PDF uses typed amount 10000" do
    _account, organization = signed_in
    ReciboFields.current.miss("partial-recibo.pdf")

    post "/supporting_documents", params: {
      kind: "recibo",
      photo: pdf_upload("partial-recibo.pdf", text_pdf("R$ 155,00")),
      amount: "100,00",
      date: "2026-05-11",
      payee: "Padaria Central"
    }

    doc = SupportingDocument.find_by!(organization: organization)
    expect(doc.amount_cents).to eq(10000)
    expect(doc.fields_origin).to eq("typed")
  end

  it "POST recibo JPEG ignores PhotoFields stays typed Padaria" do
    _account, organization = signed_in
    stub_photo_fields("recibo.jpg", payee: "Mercado Silva")

    post "/supporting_documents", params: {
      kind: "recibo", amount: "155,00", date: "2026-05-11", payee: "Padaria Central",
      photo: photo_jpg("recibo.jpg")
    }

    doc = SupportingDocument.find_by!(organization: organization)
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.fields_origin).to eq("typed")
  end

  it "POST nota_fiscal DANFE PDF does not read ReciboFields" do
    _account, organization = signed_in
    stub_photo_fields("danfe.pdf")
    expect(ReciboFields.current).not_to receive(:read)

    post "/supporting_documents", params: {
      kind: "nota_fiscal",
      photo: pdf_upload("danfe.pdf", text_pdf("EMITENTE\nVALOR TOTAL DA NOTA")),
      amount: "155,00",
      date: "2026-05-11",
      payee: "Padaria Central"
    }

    doc = SupportingDocument.find_by!(organization: organization)
    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.fields_origin).to eq("photo")
  end
end
