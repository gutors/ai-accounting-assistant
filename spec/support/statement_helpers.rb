require "csv"
require "rubyXL"

module StatementHelpers
  include ActionDispatch::TestProcess::FixtureFile

  def statement_pdf
    fixture_file_upload("extrato-maio-2026.pdf", "application/pdf")
  end

  def pagseguro_pdf
    fixture_file_upload("extrato-pagseguro-maio-2026.pdf", "application/pdf")
  end

  def bb_xlsx
    fixture_file_upload("extrato-maio-2026.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  end

  def bb_csv
    fixture_file_upload("extrato-maio-2026.csv", "text/csv")
  end

  def pagseguro_xlsx
    fixture_file_upload("extrato-pagseguro-maio-2026.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  end

  def pagseguro_movements_xlsx(rows, filename: "pagseguro-row.xlsx")
    path = Rails.root.join("tmp", filename)
    workbook = RubyXL::Workbook.new
    sheet = workbook[0]
    PagseguroSpreadsheet::HEADERS.each_with_index { |name, index| sheet.add_cell(0, index, name) }
    rows.each_with_index do |movement, offset|
      row = offset + 1
      sheet.add_cell(row, 0, movement.fetch(:data, "11/05/2026"))
      sheet.add_cell(row, 1, movement.fetch(:tipo, "Pix enviado"))
      sheet.add_cell(row, 2, movement.fetch(:descricao, "VITOR CASTRO FERREIRA"))
      sheet.add_cell(row, 3, movement[:entradas]) unless movement[:entradas].nil?
      sheet.add_cell(row, 4, movement[:saidas]) unless movement[:saidas].nil?
    end
    workbook.write(path.to_s)
    Rack::Test::UploadedFile.new(path.to_s, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  end

  def upload_path(name, content, content_type)
    path = Rails.root.join("tmp", name)
    File.binwrite(path, content)
    Rack::Test::UploadedFile.new(path.to_s, content_type)
  end

  def scrambled_xlsx
    path = Rails.root.join("tmp/scrambled.xlsx")
    workbook = RubyXL::Workbook.new
    %w[Nope Wrong Headers].each_with_index { |name, index| workbook[0].add_cell(0, index, name) }
    workbook.write(path.to_s)
    Rack::Test::UploadedFile.new(path.to_s, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  end

  def zero_row_csv
    header = "Data,observacao,Data balancete,Agencia Origem,Lote,Numero Documento,Cod. Historico,Historico,Valor R$ ,Inf.,Detalhamento Hist.\n"
    upload_path("zero.csv", header, "text/csv")
  end

  def bb_csv_with_april_row
    path = Rails.root.join("tmp/bb-april.csv")
    rows = CSV.read(Rails.root.join("spec/fixtures/files/extrato-maio-2026.csv"))
    rows << [ "01/04/2026", "", "01/04/2026", "0000", "00000", "0", "821", "Pix - Recebido", "10,00 ", "C", "fora" ]
    CSV.open(path, "w") { |csv| rows.each { |row| csv << row } }
    Rack::Test::UploadedFile.new(path.to_s, "text/csv")
  end

  def one_row_csv
    content = <<~CSV
      Data,observacao,Data balancete,Agencia Origem,Lote,Numero Documento,Cod. Historico,Historico,Valor R$ ,Inf.,Detalhamento Hist.
      20/05/2026,,20/05/2026,0000,00000,0,821,Pix - Enviado,"10,00 ",D,substituicao
    CSV
    upload_path("replace.csv", content, "text/csv")
  end

  def ofx_file
    upload_path("movements.ofx", "OFXHEADER", "application/x-ofx")
  end

  def oversized_pdf
    upload_path("oversized.pdf", "x" * 10_485_761, "application/pdf")
  end
end
