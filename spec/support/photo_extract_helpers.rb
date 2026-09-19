module PhotoExtractHelpers
  def nfce_chave
    "43260511222333000181650010000000011123456781"
  end

  def other_chave
    "43260511222333000181550010000000021987654321"
  end

  def nfce_qr_url
    "https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=#{nfce_chave}|2|1|1"
  end

  def stub_photo_symbols(name, chave: nil, qr_url: nil)
    PhotoSymbols.current.set(name, chave:, qr_url:)
  end

  def stub_photo_fields(name, amount_cents: 15500, document_on: Date.new(2026, 5, 11), payee: "Padaria Central")
    PhotoFields.current.set(name, amount_cents:, document_on:, payee:)
  end

  def stub_public_fields(url, amount_cents: 15500, payee: "Padaria Central", document_on: Date.new(2026, 5, 11))
    PublicNfceConsulta.current.set(
      url,
      PublicNfceConsulta::Fields.new(amount_cents:, payee:, document_on:)
    )
  end
end
