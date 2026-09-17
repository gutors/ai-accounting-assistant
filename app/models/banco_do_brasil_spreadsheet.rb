class BancoDoBrasilSpreadsheet
  HEADERS = [
    "Data", "observacao", "Data balancete", "Agencia Origem", "Lote",
    "Numero Documento", "Cod. Historico", "Historico", "Valor R$", "Inf.", "Detalhamento Hist."
  ].freeze
  SKIP = [ "Saldo Anterior", "S A L D O" ].freeze

  def self.read(file)
    rows = SpreadsheetGrid.rows_from(file)
    located = StatementSpreadsheet.header_map(rows, HEADERS)
    raise StatementSpreadsheet::Unreadable unless located

    header_index, map = located
    rows[(header_index + 1)..].filter_map do |row|
      next if row.nil? || row.all? { |cell| cell.to_s.strip.empty? }

      historico = StatementSpreadsheet.cell(row, map, "Historico").to_s.strip
      next if SKIP.include?(historico)

      inf = StatementSpreadsheet.cell(row, map, "Inf.").to_s.strip
      next unless inf == "C" || inf == "D"

      date = StatementSpreadsheet.parse_date(StatementSpreadsheet.cell(row, map, "Data"))
      cents = BrlCents.parse(StatementSpreadsheet.cell(row, map, "Valor R$"))
      raise StatementSpreadsheet::Unreadable if date.nil? || cents.nil?

      detalhe = StatementSpreadsheet.cell(row, map, "Detalhamento Hist.").to_s.strip
      history = detalhe.present? ? "#{historico} — #{detalhe}" : historico
      StatementSpreadsheet::Movement.new(
        occurred_on: date,
        amount_cents: cents,
        history: history,
        credit: inf == "C"
      )
    end
  end
end
