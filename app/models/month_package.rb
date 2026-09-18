class MonthPackage
  MATCHED_FOLDER = "notas"
  UNMATCHED_FOLDER = "notas-sem-casamento"

  def self.files(month, extra_unmatched: [])
    new(month, extra_unmatched: extra_unmatched).files
  end

  def self.document_package_names(document, folder: MATCHED_FOLDER)
    new(document.month).document_names(document, folder: folder)
  end

  def initialize(month, extra_unmatched: [])
    @month = month
    @extra_unmatched = Array(extra_unmatched)
  end

  def files
    tree = { "resumo-#{@month.year_month}.xlsx" => SummarySpreadsheet.bytes(@month, extra_unmatched: @extra_unmatched) }
    statement_files.each { |path, bytes| tree[path] = bytes }
    document_files.each { |path, bytes| tree[path] = bytes }
    tree
  end

  def document_names(document, folder: MATCHED_FOLDER)
    stem = document_stem(document, folder: folder)
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
    add_document_blobs(paths, matched_documents, MATCHED_FOLDER)
    add_document_blobs(paths, unmatched_documents, UNMATCHED_FOLDER)
    paths
  end

  def add_document_blobs(paths, documents, folder)
    documents.each do |document|
      stem = document_stem(document, folder: folder)
      if document.photo.attached?
        paths["#{stem}.#{blob_ext(document.photo)}"] = document.photo.download
      end
      if document.xml.attached?
        paths["#{stem}.#{blob_ext(document.xml)}"] = document.xml.download
      end
    end
  end

  def matched_documents
    SupportingDocument.where(month_id: @month.id).where.not(match_id: nil)
      .with_attached_photo.with_attached_xml.order(:id).to_a
  end

  def unmatched_documents
    persisted = SupportingDocument.where(month_id: @month.id, match_id: nil)
      .with_attached_photo.with_attached_xml.order(:id).to_a
    extras = @extra_unmatched.filter_map do |document|
      next if persisted.any? { |row| row.id == document.id }

      SupportingDocument.with_attached_photo.with_attached_xml.find(document.id)
    end
    persisted + extras
  end

  def document_stem(document, folder: MATCHED_FOLDER)
    kind = document.recibo? ? "recibo" : "nota"
    payee = ActiveSupport::Inflector.parameterize(document.payee)
    "#{folder}/#{kind}-#{document.document_on.iso8601}-#{payee}-#{document.id}"
  end

  def blob_ext(attachment)
    File.extname(attachment.filename.to_s).delete(".").downcase
  end
end
