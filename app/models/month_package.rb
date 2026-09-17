class MonthPackage
  def self.files(month)
    new(month).files
  end

  def self.document_package_names(document)
    new(document.month).document_names(document)
  end

  def initialize(month)
    @month = month
  end

  def files
    tree = { "resumo-#{@month.year_month}.xlsx" => SummarySpreadsheet.bytes(@month) }
    statement_files.each { |path, bytes| tree[path] = bytes }
    document_files.each { |path, bytes| tree[path] = bytes }
    tree
  end

  def document_names(document)
    stem = document_stem(document)
    names = []
    names << "#{stem}.#{blob_ext(document.photo)}" if document.photo.attached?
    names << "#{stem}.#{blob_ext(document.xml)}" if document.xml.attached?
    names
  end

  private

  def statement_files
    paths = {}
    @month.bank_statements.includes(:bank_account).find_each do |statement|
      slug = statement.bank_account.slug
      if statement.pdf.attached?
        paths["extratos/extrato-#{slug}.#{blob_ext(statement.pdf)}"] = statement.pdf.download
      end
      if statement.spreadsheet.attached?
        paths["extratos/extrato-#{slug}.#{blob_ext(statement.spreadsheet)}"] = statement.spreadsheet.download
      end
    end
    paths
  end

  def document_files
    paths = {}
    SupportingDocument.where(month_id: @month.id).with_attached_photo.with_attached_xml.find_each do |document|
      stem = document_stem(document)
      if document.photo.attached?
        paths["#{stem}.#{blob_ext(document.photo)}"] = document.photo.download
      end
      if document.xml.attached?
        paths["#{stem}.#{blob_ext(document.xml)}"] = document.xml.download
      end
    end
    paths
  end

  def document_stem(document)
    kind = document.recibo? ? "recibo" : "nota"
    payee = ActiveSupport::Inflector.parameterize(document.payee)
    "notas/#{kind}-#{document.document_on.iso8601}-#{payee}-#{document.id}"
  end

  def blob_ext(attachment)
    File.extname(attachment.filename.to_s).delete(".").downcase
  end
end
