class SupportingDocument
  module InsertBatch
    # Lookups (SEFAZ, OCR, public NFC-e) run per row before any transaction opens.
    # Rows only write once every row has passed, inside one transaction.
    def insert_batch(organization:, account:, documents:)
      pending = []
      Array(documents).each do |raw|
        item = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
        item = item.symbolize_keys
        file = item[:file]
        filename = file.respond_to?(:original_filename) ? file.original_filename.to_s : "arquivo"
        if item[:amount].to_s.strip.empty? || item[:date].to_s.strip.empty? || item[:payee].to_s.strip.empty?
          return [ [], "#{filename} #{BATCH_MISSING}" ]
        end

        photo, xml = slot_uploads(file, item[:photo], item[:xml])
        doc = new(organization: organization, account: account)
        doc.defer_persist = true
        doc.submit(
          kind: item[:kind],
          amount: item[:amount],
          date: item[:date],
          payee: item[:payee],
          observation: item[:observation],
          photo: photo,
          xml: xml,
          chave: item[:chave],
          skip_photo_extract: true
        )
        return [ [], doc.errors[:base].first ] unless doc.errors.empty?

        pending << doc
      end

      inserted = []
      transaction do
        pending.each do |doc|
          doc.commit_deferred!
          inserted << doc
        end
      end
      [ inserted, nil ]
    end
  end
end
