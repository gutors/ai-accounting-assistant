class SupportingDocument
  module SefazConfirm
    def confirm_identified_sefaz
      errors.clear
      if month&.closed?
        errors.add(:base, Month::CLOSED)
        return false
      end
      return true if fields_origin == ORIGIN_IDENTIFIED
      if fields_origin == ORIGIN_UPLOADED_XML
        errors.add(:base, LOCKED_FIELDS)
        return false
      end
      return fail_confirm if chave.blank?

      case consult_identified(chave)
      in SefazConsulta::Xml => consulta_xml
        parsed = AuthorizedNfe.parse(consulta_xml.bytes)
        return fail_confirm unless parsed

        persist_document(
          kind: "nota_fiscal",
          amount_cents: parsed.amount_cents,
          document_on: parsed.document_on,
          payee: parsed.payee,
          observation: observation,
          photo: nil,
          xml: nil,
          chave: parsed.chave,
          fields_origin: ORIGIN_IDENTIFIED,
          identified_xml: consulta_xml.bytes,
          sefaz_confirm_pending: false
        )
        true
      in SefazConsulta::Resumo => resumo
        persist_document(
          kind: "nota_fiscal",
          amount_cents: resumo.amount_cents,
          document_on: resumo.document_on,
          payee: resumo.payee,
          observation: observation,
          photo: nil,
          xml: nil,
          chave: chave,
          fields_origin: ORIGIN_IDENTIFIED,
          sefaz_confirm_pending: false
        )
        true
      else
        fail_confirm
      end
    end
  end
end
