module CloseHelpers
  ARCHIVE_FOLDER_ID = "15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl"

  def ready_to_close!(organization, presentation_name: "Maria Contadora")
    organization.update!(
      accountant_presentation_name: presentation_name,
      package_archive_folder_id: ARCHIVE_FOLDER_ID
    )
  end

  def attach_statement_files(statement, spreadsheet: "extrato.xlsx")
    statement.pdf.attach(io: StringIO.new("pdf-bytes"), filename: "extrato.pdf", content_type: "application/pdf")
    ext = File.extname(spreadsheet)
    type = ext == ".csv" ? "text/csv" : "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    statement.spreadsheet.attach(io: StringIO.new("sheet-bytes"), filename: spreadsheet, content_type: type)
    statement
  end

  def plant_nota(organization, account, payee:, amount:, date: "2026-05-11")
    SupportingDocument.insert(
      organization: organization,
      account: account,
      kind: "nota_fiscal",
      amount: amount,
      date: date,
      payee: payee,
      photo: photo_named("nota-#{payee.parameterize}.jpg"),
      xml: xml_file("nota-#{payee.parameterize}.xml")
    )
  end

  def writer
    PackageArchiveWriter.current
  end

  def writer_files
    writer.latest_files || {}
  end

  def parse_resumo(bytes = writer_files.fetch("resumo-2026-05.xlsx"))
    RubyXL::Parser.parse_buffer(bytes)
  end

  def sheet_cell_values(workbook)
    workbook[0].sheet_data.rows.map do |row|
      next [] unless row

      row.cells.map { |cell| cell&.value }
    end
  end

  def sheet_formulas(workbook)
    workbook[0].sheet_data.rows.flat_map do |row|
      next [] unless row

      row.cells.filter_map { |cell| cell&.formula&.expression }
    end
  end

  def sheet_text(workbook)
    sheet_cell_values(workbook).flatten.compact.map(&:to_s).join("\n")
  end

  def custos_header_row(values)
    values.find { |row| row.include?("Arquivo(s)") }
  end

  def custos_data_rows(values)
    header = custos_header_row(values)
    start = values.index(header)
    values[(start + 1)..].take_while { |row| !row.include?("Despesas total") }
  end
end
