require "rails_helper"

RSpec.describe "Month overview lists", type: :request do
  def signed_confirmed
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, statement = plant_month(organization)
    [ account, organization, month, statement ]
  end

  def query_of(href)
    uri = URI.parse(href)
    Rack::Utils.parse_query(uri.query)
  end

  def sort_link(body, fold, column)
    month_fold(body, fold).at_css(%([data-sort-column="#{column}"]))
  end

  it "GET month and matches omit leftover catalog debit from lists and missing-document sentence" do
    _account, organization, _month, statement = signed_confirmed
    plant_payment(statement, 2000, history: "Transferência — BB Rende Fácil")
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")

    get "/months/2026-05"

    expect(response.body).to include("1 pagamento com documento faltante")
    expect(rows(response.body, "payment").map { |row| row.at_css("p.font-medium")&.text }).not_to include(
      "Transferência — BB Rende Fácil"
    )
    expect(response.body).to include("Pix enviado — Padaria Central")

    get "/months/2026-05/matches"

    expect(response.body).not_to include("Transferência — BB Rende Fácil")
    expect(response.body).to include("Pix enviado — Padaria Central")
  end

  it "POST close with leftover catalog debit does not return Ha documento faltante" do
    _account, organization, month, statement = signed_confirmed
    ready_to_close!(organization)
    plant_payment(statement, 2000, history: "Transferência — BB Rende Fácil")

    post "/months/2026-05/close"

    expect(response.body).not_to include("Há documento faltante")
    expect(month.reload.closed?).to eq(true)
  end

  it "GET month defaults each list to date ascending with aria-sort" do
    account, organization, _month, statement = signed_confirmed
    later_pay = plant_payment(statement, 12000, history: "Depois", occurred_on: Date.new(2026, 5, 12))
    earlier_pay = plant_payment(statement, 10000, history: "Antes", occurred_on: Date.new(2026, 5, 11))
    plant_inflow(statement, 6300, history: "Entrada cedo")
    statement.inflows.create!(occurred_on: Date.new(2026, 5, 12), amount_cents: 4000, history: "Entrada tarde")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00", date: "2026-05-11")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "180,00", date: "2026-05-12")

    get "/months/2026-05"

    expect(rows(response.body, "payment").map { |row| row["data-payment-id"].to_i }).to eq([ earlier_pay.id, later_pay.id ])
    expect(rows(response.body, "inflow").map { |row| row.at_css("p.font-medium").text }).to eq(
      [ "Entrada cedo", "Entrada tarde" ]
    )
    expect(rows(response.body, "pool-document").map { |row| row["data-document-id"].to_i }).to eq([ padaria.id, mercado.id ])
    expect(sort_link(response.body, "Pagamentos", "date").ancestors("span").first["aria-sort"]).to eq("ascending")
    expect(sort_link(response.body, "Recebimentos", "date").ancestors("span").first["aria-sort"]).to eq("ascending")
    expect(sort_link(response.body, "Documentos sem casamento", "date").ancestors("span").first["aria-sort"]).to eq("ascending")
  end

  it "Pagamentos Valor sorts amount desc without reordering Recebimentos" do
    _account, _organization, _month, statement = signed_confirmed
    cheap = plant_payment(statement, 10000, history: "Barato", occurred_on: Date.new(2026, 5, 11))
    pricey = plant_payment(statement, 22000, history: "Caro", occurred_on: Date.new(2026, 5, 12))
    plant_inflow(statement, 6300, history: "Entrada cedo")
    statement.inflows.create!(occurred_on: Date.new(2026, 5, 12), amount_cents: 4000, history: "Entrada tarde")

    get "/months/2026-05"
    get sort_link(response.body, "Pagamentos", "amount")["href"]

    query = query_of(request.original_fullpath)
    expect(query["payments_sort"]).to eq("amount")
    expect(query["payments_dir"]).to eq("desc")
    expect(rows(response.body, "payment").map { |row| row["data-payment-id"].to_i }).to eq([ pricey.id, cheap.id ])
    expect(rows(response.body, "inflow").map { |row| row.at_css("p.font-medium").text }).to eq(
      [ "Entrada cedo", "Entrada tarde" ]
    )
  end

  it "Pagamentos Valor toggles amount dir from desc to asc" do
    _account, _organization, _month, statement = signed_confirmed
    plant_payment(statement, 10000, history: "Barato")
    plant_payment(statement, 22000, history: "Caro")

    get "/months/2026-05", params: { payments_sort: "amount", payments_dir: "desc" }
    get sort_link(response.body, "Pagamentos", "amount")["href"]

    expect(query_of(request.original_fullpath)["payments_dir"]).to eq("asc")
  end

  it "Recebimentos Data sort keeps Pagamentos amount sort" do
    _account, _organization, _month, statement = signed_confirmed
    cheap = plant_payment(statement, 10000, history: "Barato", occurred_on: Date.new(2026, 5, 11))
    pricey = plant_payment(statement, 22000, history: "Caro", occurred_on: Date.new(2026, 5, 12))
    plant_inflow(statement, 6300, history: "Entrada cedo")
    statement.inflows.create!(occurred_on: Date.new(2026, 5, 12), amount_cents: 4000, history: "Entrada tarde")

    get "/months/2026-05", params: { payments_sort: "amount", payments_dir: "desc" }
    get sort_link(response.body, "Recebimentos", "date")["href"]

    query = query_of(request.original_fullpath)
    expect(query["payments_sort"]).to eq("amount")
    expect(rows(response.body, "payment").map { |row| row["data-payment-id"].to_i }).to eq([ pricey.id, cheap.id ])
    expect(rows(response.body, "inflow").map { |row| row.at_css("p.font-medium").text }).to eq(
      [ "Entrada tarde", "Entrada cedo" ]
    )
  end

  it "pool Favorecido sorts by payee" do
    account, organization, _month, _statement = signed_confirmed
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00", date: "2026-05-11")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "180,00", date: "2026-05-12")

    get "/months/2026-05"
    get sort_link(response.body, "Documentos sem casamento", "payee")["href"]

    expect(query_of(request.original_fullpath)["pool_sort"]).to eq("payee")
    expect(rows(response.body, "pool-document").map { |row| row["data-document-id"].to_i }).to eq([ padaria.id, mercado.id ])
  end

  it "pool Valor sorts by amount_cents" do
    account, organization, _month, _statement = signed_confirmed
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00", date: "2026-05-11")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "180,00", date: "2026-05-12")

    get "/months/2026-05"
    get sort_link(response.body, "Documentos sem casamento", "amount")["href"]

    expect(rows(response.body, "pool-document").map { |row| row["data-document-id"].to_i }).to eq([ padaria.id, mercado.id ])
  end

  it "sort header URLs keep bank_account_id" do
    _account, organization, _month, statement = signed_confirmed
    plant_payment(statement, 22000)
    bank_account_id = statement.bank_account_id

    get "/months/2026-05", params: { bank_account_id: bank_account_id }

    href = sort_link(response.body, "Pagamentos", "amount")["href"]
    expect(query_of(href)["bank_account_id"]).to eq(bank_account_id.to_s)
  end

  it "invalid sort and dir params fall back to date ascending" do
    account, organization, _month, statement = signed_confirmed
    later = plant_payment(statement, 10000, history: "Depois", occurred_on: Date.new(2026, 5, 12))
    earlier = plant_payment(statement, 22000, history: "Antes", occurred_on: Date.new(2026, 5, 11))
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00", date: "2026-05-11")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "180,00", date: "2026-05-12")

    [
      { payments_sort: "history", payments_dir: "sideways" },
      { payments_sort: "amount", payments_dir: "sideways" },
      { payments_sort: "history", payments_dir: "desc" }
    ].each do |params|
      get "/months/2026-05", params: params
      expect(rows(response.body, "payment").map { |row| row["data-payment-id"].to_i }).to eq([ earlier.id, later.id ])
      expect(sort_link(response.body, "Pagamentos", "date").ancestors("span").first["aria-sort"]).to eq("ascending")
    end

    get "/months/2026-05", params: { pool_sort: "kind", pool_dir: "asc" }
    expect(rows(response.body, "pool-document").map { |row| row["data-document-id"].to_i }).to eq([ padaria.id, mercado.id ])
  end

  it "Pagamentos status includes Documento faltante without document Sugestao" do
    account, organization, _month, statement = signed_confirmed
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Documento faltante")
    expect(status).not_to include("Sugestão")
  end

  it "Pagamentos status includes Documento faltante without Sugestao de excecao" do
    _account, organization, _month, statement = signed_confirmed
    organization.update!(accountant_presentation_name: "Ana Contadora", accountant_pix_key: "chave-pix")
    plant_payment(statement, 22000, history: "Pix enviado chave-pix")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado chave-pix")
    expect(status).to include("Documento faltante")
    expect(status).not_to include("Sugestão de exceção")
  end

  it "pool heads are Data Favorecido Tipo Valor Foto without checkbox or Devolver" do
    account, organization, _month, _statement = signed_confirmed
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    head = month_fold(response.body, "Documentos sem casamento").at_css(".ledger-head")
    expect(head.element_children.map { |node| node.text.strip }).to eq(
      [ "Data", "Favorecido", "Tipo", "Valor", "Foto" ]
    )
    expect(response.body).not_to include('name="supporting_document_ids[]"')
    expect(month_fold(response.body, "Documentos sem casamento").text).not_to include("Devolver")
  end

  it "pool lists unmatched month document payee without Devolver" do
    account, organization, month, _statement = signed_confirmed
    packed = plant_recibo(organization, account, payee: "Mercado Silva", amount: "50,00", date: "2026-05-18")
    packed.update!(month_id: month.id)

    get "/months/2026-05"

    row = row(response.body, "pool-document", document_id: packed.id)
    expect(row.text).to include("Mercado Silva")
    expect(row.text).not_to include("Devolver")
  end
end
