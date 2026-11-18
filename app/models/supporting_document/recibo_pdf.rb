class SupportingDocument
  module ReciboPdf
    def overlay_recibo_pdf(extract_source, incoming_photo, next_kind, skip_photo_extract, next_cents, next_on, next_payee)
      fields = read_recibo_pdf_fields(extract_source, incoming_photo, next_kind, skip_photo_extract)
      return [ fields, next_cents, next_on, next_payee ] unless fields

      [ fields, fields.amount_cents, fields.document_on, fields.payee ]
    end

    def origin_after_submit(next_kind, recibo_fields, incoming_xml, parsed_nfe, identified_xml, identified_resumo, public_fields, photo_fields)
      if next_kind == "recibo"
        recibo_fields ? ORIGIN_PHOTO : (fields_origin.presence || ORIGIN_TYPED)
      elsif incoming_xml && parsed_nfe
        ORIGIN_UPLOADED_XML
      elsif identified_xml || identified_resumo
        ORIGIN_IDENTIFIED
      elsif public_fields
        ORIGIN_NFC_E_PUBLIC
      elsif photo_fields
        ORIGIN_PHOTO
      else
        fields_origin.presence || ORIGIN_TYPED
      end
    end

    def read_recibo_pdf_fields(extract_source, incoming_photo, next_kind, skip_photo_extract)
      return if next_kind != "recibo" || skip_photo_extract || persisted?

      source = extract_source || photo_source_for_extract(incoming_photo, next_kind)
      return unless pdf_extract?(source)

      case ReciboFields.current.read(bytes: source[:bytes], filename: source[:filename])
      in ReciboFields::Fields => fields if complete_triple?(fields.amount_cents, fields.document_on, fields.payee)
        fields
      else
        nil
      end
    end

    def pdf_extract?(source)
      return false if source.nil?

      File.extname(source[:filename].to_s).downcase == ".pdf" || PhotoPdf.pdf?(source[:bytes])
    end
  end
end
