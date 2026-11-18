require "rails_helper"

RSpec.describe "Supporting documents Sem mês list", type: :request do
  def signed_in
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    [ account, organization ]
  end

  def plant_doc(organization, account, payee:, amount: "155,00", date: "2026-05-11", kind: "recibo", filename: "recibo.jpg")
    SupportingDocument.insert(
      organization: organization,
      account: account,
      kind: kind,
      amount: amount,
      date: date,
      payee: payee,
      photo: upload_path(filename, "jpeg-bytes", "image/jpeg")
    )
  end

  def listed_payees(body = response.body)
    page_doc(body).css('#sem-mes li[data-row="document"] [data-cell="payee"] p.font-medium').map(&:text)
  end

  it "GET /supporting_documents excludes matched documents from Sem mes" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    month, statement = plant_month(organization)
    payment_coord = plant_payment(statement, 15500)
    payment_sub = plant_payment(statement, 22000)

    matched_coord = plant_doc(organization, coord, payee: "Padaria Casada", amount: "155,00")
    matched_sub = plant_doc(organization, submitter, payee: "Mercado Casado Sub", amount: "220,00")
    unmatched_doc = plant_doc(organization, submitter, payee: "Papelaria Aberta", amount: "48,90")

    Match.confirm(month: month, payments: [ payment_coord ], supporting_documents: [ matched_coord ])
    Match.confirm(month: month, payments: [ payment_sub ], supporting_documents: [ matched_sub ])

    sign_in_as(coord, organization: organization)
    get "/supporting_documents"

    expect(response).to have_http_status(:ok)
    expect(listed_payees).to eq([ unmatched_doc.payee ])
    expect(response.body).not_to include("Padaria Casada")
    expect(response.body).not_to include("Mercado Casado Sub")

    sign_in_as(submitter, organization: organization)
    get "/supporting_documents"

    expect(response).to have_http_status(:ok)
    expect(listed_payees).to eq([ unmatched_doc.payee ])
    expect(response.body).not_to include("Mercado Casado Sub")
  end

  it "GET /supporting_documents includes unmatched document with no month" do
    account, organization = signed_in
    doc = plant_doc(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/supporting_documents"

    expect(response).to have_http_status(:ok)
    expect(listed_payees).to eq([ doc.payee ])
  end

  it "GET /supporting_documents includes unmatched closed-package document with Sem casamento" do
    account, organization = signed_in
    ready_to_close!(organization)
    plant_month(organization)
    doc = plant_doc(organization, account, payee: "Padaria Avulsa", amount: "155,00")
    post "/months/2026-05/close", params: { supporting_document_ids: [ doc.id ] }

    get "/supporting_documents"

    expect(response).to have_http_status(:ok)
    expect(listed_payees).to eq([ "Padaria Avulsa" ])
    expect(page_doc(response.body).at_css("#sem-mes").text).to include("Sem casamento em 2026-05")
  end

  it "GET /supporting_documents filters Sem mes by q kind and date range and shows Limpar" do
    account, organization = signed_in
    plant_doc(organization, account, payee: "Padaria Central", kind: "nota_fiscal", date: "2026-05-08")
    plant_doc(organization, account, payee: "Papelaria Lume", kind: "recibo", date: "2026-05-11")
    plant_doc(organization, account, payee: "Papelaria Sul", kind: "nota_fiscal", date: "2026-05-11")
    plant_doc(organization, account, payee: "Papelaria Antiga", kind: "recibo", date: "2026-05-02")

    get "/supporting_documents"
    expect(page_doc(response.body).css("#sem-mes a").find { |a| a.text.strip == "Limpar" }).to be_nil

    get "/supporting_documents", params: {
      q: "papelaria",
      kind: "recibo",
      date_from: "2026-05-10",
      date_to: "2026-05-12"
    }

    expect(response).to have_http_status(:ok)
    expect(listed_payees).to eq([ "Papelaria Lume" ])
    limpar = page_doc(response.body).css("#sem-mes a").find { |a| a.text.strip == "Limpar" }
    expect(limpar).not_to be_nil
    expect(limpar["href"]).to eq("/supporting_documents")
  end

  it "GET /supporting_documents defaults to date descending with sort header links" do
    account, organization = signed_in
    plant_doc(organization, account, payee: "Doc Antigo", date: "2026-05-08")
    plant_doc(organization, account, payee: "Doc Novo", date: "2026-05-14")

    get "/supporting_documents"

    expect(response).to have_http_status(:ok)
    expect(listed_payees).to eq([ "Doc Novo", "Doc Antigo" ])
    head = page_doc(response.body).at_css("#sem-mes .ledger-head.ledger-doc")
    date_cell = head.element_children.first
    amount_cell = head.element_children[3]
    expect(date_cell["aria-sort"]).to eq("descending")
    expect(date_cell.at_css("a")["href"]).to eq("/supporting_documents?dir=asc&sort=date")
    expect(amount_cell["aria-sort"]).to eq("none")
    expect(amount_cell.at_css("a")["href"]).to eq("/supporting_documents?dir=desc&sort=amount")
  end

  it "GET /supporting_documents sorts by date ascending" do
    account, organization = signed_in
    plant_doc(organization, account, payee: "Doc Antigo", date: "2026-05-08")
    plant_doc(organization, account, payee: "Doc Novo", date: "2026-05-14")

    get "/supporting_documents", params: { sort: "date", dir: "asc" }

    expect(response).to have_http_status(:ok)
    expect(listed_payees).to eq([ "Doc Antigo", "Doc Novo" ])
    head = page_doc(response.body).at_css("#sem-mes .ledger-head.ledger-doc")
    date_cell = head.element_children.first
    expect(date_cell["aria-sort"]).to eq("ascending")
    expect(date_cell.at_css("a")["href"]).to eq("/supporting_documents?dir=desc&sort=date")
  end

  it "GET /supporting_documents sorts by amount desc and asc and preserves filter params" do
    account, organization = signed_in
    plant_doc(organization, account, payee: "Papelaria Barata", kind: "recibo", amount: "48,90", date: "2026-05-12")
    plant_doc(organization, account, payee: "Papelaria Cara", kind: "recibo", amount: "320,00", date: "2026-05-08")
    plant_doc(organization, account, payee: "Papelaria Media", kind: "recibo", amount: "155,00", date: "2026-05-10")

    get "/supporting_documents", params: { q: "Papelaria", kind: "recibo", sort: "amount", dir: "desc" }

    expect(response).to have_http_status(:ok)
    expect(listed_payees).to eq([ "Papelaria Cara", "Papelaria Media", "Papelaria Barata" ])
    head = page_doc(response.body).at_css("#sem-mes .ledger-head.ledger-doc")
    amount_cell = head.element_children[3]
    expect(amount_cell["aria-sort"]).to eq("descending")
    expect(amount_cell.at_css("a")["href"]).to include("q=Papelaria")
    expect(amount_cell.at_css("a")["href"]).to include("kind=recibo")
    expect(amount_cell.at_css("a")["href"]).to include("sort=amount")
    expect(amount_cell.at_css("a")["href"]).to include("dir=asc")

    get "/supporting_documents", params: { q: "Papelaria", kind: "recibo", sort: "amount", dir: "asc" }

    expect(listed_payees).to eq([ "Papelaria Barata", "Papelaria Media", "Papelaria Cara" ])
    head_asc = page_doc(response.body).at_css("#sem-mes .ledger-head.ledger-doc")
    expect(head_asc.element_children[3]["aria-sort"]).to eq("ascending")
  end

  it "GET /supporting_documents renders SVG icon actions for Editar and Excluir" do
    account, organization = signed_in
    doc = plant_doc(organization, account, payee: "Padaria Central")

    get "/supporting_documents"

    document_row = row(response.body, "document", document_id: doc.id)
    actions = document_row.at_css('[data-cell="actions"]')
    edit_link = actions.at_css('a[aria-label="Editar"]')
    expect(edit_link).not_to be_nil
    expect(edit_link["href"]).to eq("/supporting_documents/#{doc.id}/edit")
    expect(edit_link["title"]).to eq("Editar")
    expect(edit_link.at_css("svg")).not_to be_nil

    delete_btn = actions.at_css('button[aria-label="Excluir"]')
    expect(delete_btn).not_to be_nil
    expect(delete_btn["title"]).to eq("Excluir")
    expect(delete_btn.at_css("svg")).not_to be_nil
    form = delete_btn.ancestors("form").first
    expect(form["action"]).to eq("/supporting_documents/#{doc.id}")
    expect(form["data-turbo-confirm"]).to eq("Excluir este documento?")
  end

  it "GET /supporting_documents omits Excluir icon when document belongs to a month" do
    account, organization = signed_in
    month, _statement = plant_month(organization)
    doc = plant_doc(organization, account, payee: "Padaria Central")
    doc.update!(month_id: month.id)

    get "/supporting_documents"

    document_row = row(response.body, "document", document_id: doc.id)
    actions = document_row.at_css('[data-cell="actions"]')
    expect(actions.at_css('a[aria-label="Editar"]')).not_to be_nil
    expect(actions.at_css('button[aria-label="Excluir"]')).to be_nil
  end

  it "submitter justification checkboxes remain available when Sem mes filter matches nothing" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    doc = plant_doc(organization, submitter, payee: "Padaria Central")

    get "/supporting_documents", params: { q: "Inexistente" }

    expect(response).to have_http_status(:ok)
    expect(page_doc(response.body).at_css("#sem-mes").text).to include("Nenhum documento")
    checkbox = page_doc(response.body).at_css("input#supporting_document_#{doc.id}")
    expect(checkbox).not_to be_nil
  end
end
