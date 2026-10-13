class StatementSpreadsheet
  class Unreadable < StandardError; end
  Movement = Struct.new(:occurred_on, :amount_cents, :history, :credit, keyword_init: true)

  def self.header_map(rows, required)
    rows.each_with_index do |row, index|
      next unless row

      positions = {}
      row.each_with_index do |cell, col|
        name = cell.to_s.strip
        positions[name] = col unless name.empty?
      end
      return [ index, positions ] if required.all? { |name| positions.key?(name) }
    end
    nil
  end

  def self.cell(row, map, name)
    index = map[name]
    return if index.nil?

    row[index]
  end

  def self.parse_date(value)
    return value if value.is_a?(Date)
    return value.to_date if value.respond_to?(:to_date) && !value.is_a?(String)

    Date.strptime(value.to_s.strip, "%d/%m/%Y")
  rescue ArgumentError, TypeError
    nil
  end

  def self.present_amount?(value)
    cents = BrlCents.parse(value)
    cents.is_a?(Integer) && cents.positive?
  end
end
