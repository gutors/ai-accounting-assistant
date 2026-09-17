class SummarySpreadsheet
  INFLOW_HEADERS = [ "Data", "Valor", "Onde", "Item", "Detalhe" ].freeze
  EXPENSE_HEADERS = [ "Data", "Valor", "Onde", "O que", "Detalhes", "Exceção", "Arquivo(s)", "Observação" ].freeze
  EXCEPTION_COPY = {
    "bank_fee" => "Tarifa bancária",
    "accountant_fee" => "Honorário do contador"
  }.freeze

  def self.bytes(month)
    new(month).bytes
  end

  def self.workbook(month)
    new(month).workbook
  end

  def initialize(month)
    @month = month
    @organization = month.organization
  end

  def bytes
    workbook.stream.string.b
  end

  def workbook
    book = RubyXL::Workbook.new
    sheet = book.worksheets[0]
    sheet.sheet_name = @month.year_month
    row = write_header(sheet)
    row = write_recebimentos(sheet, row)
    write_custos(sheet, row)
    book
  end

  private

  def write_header(sheet)
    row = 0
    sheet.add_cell(row, 0, "Planilha-resumo — #{@organization.name}")
    row += 1
    sheet.add_cell(row, 0, @organization.accountant_presentation_name.to_s)
    row += 1
    tax_id = @organization.accountant_tax_id
    if BrazilianTaxId.cnpj?(tax_id) && @organization.accountant_legal_name.present?
      sheet.add_cell(row, 0, @organization.accountant_legal_name)
      row += 1
    end
    if tax_id.present?
      sheet.add_cell(row, 0, BrazilianTaxId.format(tax_id))
      row += 1
    end
    row + 1
  end

  def write_recebimentos(sheet, row)
    sheet.add_cell(row, 0, "Recebimentos")
    row += 1
    INFLOW_HEADERS.each_with_index { |header, index| sheet.add_cell(row, index, header) }
    row += 1
    start_row = row
    inflows.each do |inflow|
      sheet.add_cell(row, 0, format_date(inflow.occurred_on))
      sheet.add_cell(row, 1, excel_amount(inflow.amount_cents))
      sheet.add_cell(row, 2, inflow.bank_statement.bank_account.name)
      sheet.add_cell(row, 3, inflow.history)
      sheet.add_cell(row, 4, "")
      row += 1
    end
    end_row = row - 1
    sheet.add_cell(row, 0, "Receita total")
    sheet.add_cell(row, 1, nil, sum_formula(start_row, end_row))
    @receita_row = row
    row + 2
  end

  def write_custos(sheet, row)
    sheet.add_cell(row, 0, "Custos/Despesas")
    row += 1
    EXPENSE_HEADERS.each_with_index { |header, index| sheet.add_cell(row, index, header) }
    row += 1
    start_row = row
    expenses.each do |payment|
      sheet.add_cell(row, 0, format_date(payment.occurred_on))
      sheet.add_cell(row, 1, excel_amount(payment.amount_cents))
      sheet.add_cell(row, 2, payment.bank_statement.bank_account.name)
      sheet.add_cell(row, 3, payment.history)
      sheet.add_cell(row, 4, "")
      sheet.add_cell(row, 5, EXCEPTION_COPY[payment.document_exception_kind] || "")
      sheet.add_cell(row, 6, arquivo_cell(payment))
      sheet.add_cell(row, 7, payment.match&.observation.to_s)
      row += 1
    end
    end_row = row - 1
    sheet.add_cell(row, 0, "Despesas total")
    sheet.add_cell(row, 1, nil, sum_formula(start_row, end_row))
    @despesas_row = row
    row += 1
    sheet.add_cell(row, 0, "Resultado mês")
    sheet.add_cell(row, 1, nil, "B#{excel_row(@receita_row)}-B#{excel_row(@despesas_row)}")
    row
  end

  def inflows
    Inflow.joins(:bank_statement).where(bank_statements: { month_id: @month.id })
      .includes(bank_statement: :bank_account).order(:occurred_on, :id)
  end

  def expenses
    Payment.joins(:bank_statement).where(bank_statements: { month_id: @month.id })
      .includes(match: :supporting_documents, bank_statement: :bank_account).order(:occurred_on, :id)
  end

  def arquivo_cell(payment)
    return "" unless payment.match_id.present?

    payment.match.supporting_documents.sort_by { |document| [ document.document_on, document.id ] }
      .flat_map { |document| MonthPackage.document_package_names(document) }
      .join("; ")
  end

  def format_date(date)
    date.strftime("%d/%m/%Y")
  end

  def excel_amount(cents)
    if (cents % 100).zero?
      cents / 100
    else
      cents / 100.0
    end
  end

  def sum_formula(start_row, end_row)
    if end_row < start_row
      "SUM(0)"
    else
      "SUM(B#{excel_row(start_row)}:B#{excel_row(end_row)})"
    end
  end

  def excel_row(index)
    index + 1
  end
end
