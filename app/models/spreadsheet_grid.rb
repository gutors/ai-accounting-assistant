require "csv"
require "rubyXL"

class SpreadsheetGrid
  def self.rows_from(file)
    filename = filename_of(file)
    ext = File.extname(filename).downcase
    bytes = read_bytes(file)
    case ext
    when ".xlsx" then xlsx_rows(bytes)
    when ".csv" then csv_rows(bytes)
    else
      raise StatementSpreadsheet::Unreadable
    end
  end

  def self.filename_of(file)
    if file.respond_to?(:original_filename)
      file.original_filename.to_s
    elsif file.respond_to?(:filename)
      file.filename.to_s
    else
      File.basename(file.path)
    end
  end

  def self.read_bytes(file)
    if file.respond_to?(:rewind)
      file.rewind
      bytes = file.read
      file.rewind
      bytes
    else
      File.binread(file.path)
    end
  end

  def self.xlsx_rows(bytes)
    workbook = RubyXL::Parser.parse_buffer(bytes)
    sheet = workbook.worksheets.first
    raise StatementSpreadsheet::Unreadable unless sheet

    rows = []
    sheet.each do |row|
      if row.nil?
        rows << []
        next
      end
      values = []
      row.cells.each do |cell|
        next unless cell

        values[cell.column] = cell.value
      end
      rows << values
    end
    rows
  rescue Zip::Error, ArgumentError
    raise StatementSpreadsheet::Unreadable
  end

  def self.csv_rows(bytes)
    text = bytes.to_s
    utf8 = text.dup.force_encoding("UTF-8")
    text = utf8.valid_encoding? ? utf8 : text.dup.force_encoding("Windows-1252").encode("UTF-8")
    first = text.lines.first.to_s
    sep = first.count(";") > first.count(",") ? ";" : ","
    CSV.parse(text, col_sep: sep)
  rescue CSV::MalformedCSVError, ArgumentError
    raise StatementSpreadsheet::Unreadable
  end

  private_class_method :xlsx_rows, :csv_rows
end
