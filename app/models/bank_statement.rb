class BankStatement < ApplicationRecord
  MAX_BYTES = 10_485_760
  SPREADSHEET_EXT = %w[.csv .xlsx].freeze
  MISSING_FILES = "Envie o PDF e a planilha"
  UNREADABLE = "Não foi possível ler a planilha"
  UNSUPPORTED_BANK = "Este banco ainda não tem leitura de planilha"
  OVERSIZE = "Cada arquivo pode ter no máximo 10 MB"

  belongs_to :month
  belongs_to :bank_account
  has_many :inflows, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_one_attached :pdf
  has_one_attached :spreadsheet

  def self.import(month:, bank_account:, pdf:, spreadsheet:)
    record = find_or_initialize_by(month: month, bank_account: bank_account)
    record.submit(pdf: pdf, spreadsheet: spreadsheet)
    record
  rescue ActiveRecord::RecordNotUnique
    find_by!(month: month, bank_account: bank_account).tap do |existing|
      existing.submit(pdf: pdf, spreadsheet: spreadsheet)
    end
  end

  def submit(pdf:, spreadsheet:)
    errors.clear
    unless bank_account.active?
      errors.add(:base, "inactive")
      return self
    end

    if pdf.blank? || spreadsheet.blank? || !spreadsheet_ext?(spreadsheet)
      errors.add(:base, MISSING_FILES)
      return self
    end

    if oversized?(pdf) || oversized?(spreadsheet)
      errors.add(:base, OVERSIZE)
      return self
    end

    reader = reader_for(bank_account.bank.compe)
    unless reader
      errors.add(:base, UNSUPPORTED_BANK)
      return self
    end

    begin
      movements = reader.read(spreadsheet)
    rescue StatementSpreadsheet::Unreadable
      errors.add(:base, UNREADABLE)
      return self
    end

    outside = movements.reject { |movement| in_opened_month?(movement.occurred_on) }
    if outside.any?
      errors.add(:base, "A planilha tem movimentação fora de #{month.year_month}")
      return self
    end

    persist_import(pdf: pdf, spreadsheet: spreadsheet, movements: movements)
    self
  end

  private

  def spreadsheet_ext?(file)
    name = SpreadsheetGrid.filename_of(file)
    SPREADSHEET_EXT.include?(File.extname(name).downcase)
  end

  def oversized?(file)
    size = if file.respond_to?(:size) && file.size
      file.size
    else
      SpreadsheetGrid.read_bytes(file).bytesize
    end
    size > MAX_BYTES
  end

  def reader_for(compe)
    case compe
    when "001" then BancoDoBrasilSpreadsheet
    when "290" then PagseguroSpreadsheet
    end
  end

  def in_opened_month?(date)
    year, month_number = month.year_month.split("-").map(&:to_i)
    date.year == year && date.month == month_number
  end

  def persist_import(pdf:, spreadsheet:, movements:)
    transaction do
      save!
      inflows.destroy_all
      payments.destroy_all
      movements.each do |movement|
        attrs = { occurred_on: movement.occurred_on, amount_cents: movement.amount_cents, history: movement.history }
        if movement.credit
          inflows.create!(attrs)
        else
          payments.create!(attrs)
        end
      end
      self.pdf.attach(pdf)
      self.spreadsheet.attach(spreadsheet)
    end
  end
end
