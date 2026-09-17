require "rails_helper"

RSpec.describe SummarySpreadsheet, type: :model do
  def organization
    @organization ||= Organization.create!(name: "ONG Norte")
  end

  def account
    @account ||= Account.create!(email: "coord@example.com", google_uid: "uid-sheet")
  end

  def month_and_statement
    @month_and_statement ||= plant_month(organization)
  end

  def month
    month_and_statement[0]
  end

  def statement
    month_and_statement[1]
  end

  def book
    RubyXL::Parser.parse_buffer(SummarySpreadsheet.bytes(month))
  end

  it "workbook has one sheet 2026-05 titled Planilha-resumo ONG Norte" do
    parsed = book

    expect(parsed.worksheets.size).to eq(1)
    expect(parsed[0].sheet_name).to eq("2026-05")
    expect(sheet_text(parsed)).to include("Planilha-resumo — ONG Norte")
  end

  it "header includes name razao social and formatted CNPJ" do
    organization.update_accountant(
      presentation_name: "Maria Contadora",
      tax_id: "11222333000181",
      legal_name: "Contábil LTDA"
    )
    text = sheet_text(book)

    expect(text).to include("Maria Contadora")
    expect(text).to include("Contábil LTDA")
    expect(text).to include("11.222.333/0001-81")
  end

  it "CPF header includes formatted CPF and omits razao social" do
    organization.update_accountant(presentation_name: "Maria Contadora", tax_id: "39053344705")
    text = sheet_text(book)

    expect(text).to include("390.533.447-05")
    expect(text).not_to include("Contábil LTDA")
  end

  it "header omits PIX and destination email" do
    organization.update_accountant(
      presentation_name: "Maria Contadora",
      pix_key: "chave-pix",
      destination_email: "ana@example.com"
    )
    text = sheet_text(book)

    expect(text).not_to include("chave-pix")
    expect(text).not_to include("ana@example.com")
  end

  it "Recebimentos row is date 63 Conta Principal Pix - Recebido" do
    plant_inflow(statement, 6300, history: "Pix - Recebido")
    row = sheet_cell_values(book).find { |cells| cells.include?("04/05/2026") && cells.include?(63) }

    expect(row).to include("Conta Principal", "Pix - Recebido")
  end

  it "bank_fee expense is Tarifa bancaria 155 empty Arquivos" do
    payment = plant_payment(statement, 15500, history: "Tarifa Pacote de Serviços")
    payment.mark_document_exception("bank_fee")
    values = sheet_cell_values(book)
    header = custos_header_row(values)
    row = custos_data_rows(values).find { |cells| cells.include?("Tarifa bancária") }

    expect(row).to include(155, "Tarifa Pacote de Serviços")
    expect(row[header.index("Arquivo(s)")]).to eq("")
  end

  it "1N Arquivos is two notas names separated by semicolon space" do
    payment = plant_payment(statement, 22000)
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "100,00", date: "2026-05-11")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "120,00", date: "2026-05-12")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ padaria, mercado ])
    names = [ padaria, mercado ].flat_map { |document| MonthPackage.document_package_names(document.reload) }
    joined = names.join("; ")
    row = custos_data_rows(sheet_cell_values(book)).find { |cells| cells.include?(220) }

    expect(row).to include(joined)
    expect(joined).to include("; ")
  end

  it "N1 both rows carry the same notas filename" do
    pay_a = plant_payment(statement, 10000, occurred_on: Date.new(2026, 5, 4))
    pay_b = plant_payment(statement, 12000, occurred_on: Date.new(2026, 5, 20))
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ pay_a, pay_b ], supporting_documents: [ document ])
    filename = MonthPackage.document_package_names(document.reload).first
    rows = custos_data_rows(sheet_cell_values(book)).select { |cells| cells.intersect?([ 100, 120 ]) }

    expect(rows.size).to eq(2)
    expect(rows).to all(include(filename))
  end

  it "observation desconto nao documentado is on the expense row" do
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "200,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ], observation: "desconto não documentado")
    row = custos_data_rows(sheet_cell_values(book)).find { |cells| cells.include?(220) }

    expect(row).to include("desconto não documentado")
  end

  it "Receita and Despesas formulas include SUM and Resultado includes minus" do
    parsed = book
    text = sheet_text(parsed)

    expect(text).to include("Receita total", "Despesas total", "Resultado mês")
    expect(formula_beside_label(parsed, "Receita total")).to include("SUM")
    expect(formula_beside_label(parsed, "Despesas total")).to include("SUM")
    expect(formula_beside_label(parsed, "Resultado mês")).to include("-")
  end

  it "sheet includes Recebimentos section title" do
    expect(sheet_cell_values(book).flatten).to include("Recebimentos")
  end

  it "sheet includes Custos/Despesas section title" do
    expect(sheet_cell_values(book).flatten).to include("Custos/Despesas")
  end

  it "sheet includes Detalhe column header" do
    expect(sheet_cell_values(book).flatten).to include("Detalhe")
  end

  it "sheet includes Detalhes column header" do
    expect(sheet_cell_values(book).flatten).to include("Detalhes")
  end

  it "workbook text does not include sem casamento" do
    expect(sheet_text(book)).not_to include("sem casamento")
  end

  it "expense rows are ordered 2026-05-04 then 2026-05-20" do
    first = plant_payment(statement, 10000, occurred_on: Date.new(2026, 5, 4))
    second = plant_payment(statement, 12000, occurred_on: Date.new(2026, 5, 20))
    first.mark_document_exception("bank_fee")
    second.mark_document_exception("bank_fee")
    dates = custos_data_rows(sheet_cell_values(book)).map(&:first)

    expect(dates).to eq([ "04/05/2026", "20/05/2026" ])
  end

  it "accountant_fee expense is Honorario do contador" do
    payment = plant_payment(statement, 15500)
    payment.mark_document_exception("accountant_fee")

    expect(sheet_text(book)).to include("Honorário do contador")
  end
end
