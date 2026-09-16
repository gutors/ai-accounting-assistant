class PagseguroSpreadsheet
  HEADERS = [ "Data", "Tipo", "Descrição", "Entradas", "Saidas", "Saldo" ].freeze

  def self.read(file)
    rows = SpreadsheetGrid.rows_from(file)
    located = StatementSpreadsheet.header_map(rows, HEADERS)
    raise StatementSpreadsheet::Unreadable unless located

    header_index, map = located
    rows[(header_index + 1)..].filter_map do |row|
      next if row.nil? || row.all? { |cell| cell.to_s.strip.empty? }

      tipo = StatementSpreadsheet.cell(row, map, "Tipo").to_s.strip
      next if tipo.start_with?("Saldo do dia")

      entradas = StatementSpreadsheet.cell(row, map, "Entradas")
      saidas = StatementSpreadsheet.cell(row, map, "Saidas")
      credit = StatementSpreadsheet.present_amount?(entradas)
      debit = StatementSpreadsheet.present_amount?(saidas)
      next unless credit || debit

      date = StatementSpreadsheet.parse_date(StatementSpreadsheet.cell(row, map, "Data"))
      cents = BrlCents.parse(credit ? entradas : saidas)
      raise StatementSpreadsheet::Unreadable if date.nil? || cents.nil?

      descricao = StatementSpreadsheet.cell(row, map, "Descrição").to_s.strip
      history = descricao.present? ? "#{tipo} — #{descricao}" : tipo
      StatementSpreadsheet::Movement.new(
        occurred_on: date,
        amount_cents: cents,
        history: history,
        credit: credit
      )
    end
  end
end
