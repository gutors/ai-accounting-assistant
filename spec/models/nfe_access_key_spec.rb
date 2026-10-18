require "rails_helper"

RSpec.describe NfeAccessKey, type: :model do
  def cupom_chave
    "43260511222333000181650330000000011123456780"
  end

  it "reads 44 consecutive digits" do
    expect(described_class.digits("x#{cupom_chave}y")).to eq(cupom_chave)
  end

  it "reads eleven grouped blocks of four digits" do
    grouped = cupom_chave.scan(/.{4}/).join(" ")

    expect(described_class.digits("Chave #{grouped}")).to eq(cupom_chave)
  end

  it "assembles NFC-e chave from a mangled cupom reading" do
    text = <<~TEXT
      Documento Auxiliar da Nota Fiscal de Consumidor Eletronica
      Consulte pela Chave de Acesso em
      https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx
      4326 0511 2223 3300 0181 403 3000 0000 0111 2345 6780
      HFC-e 000000001 Serie-833 11/05/2026 17:14:48
      ESTAB 911222333000181
    TEXT

    expect(described_class.digits(text)).to eq(cupom_chave)
  end

  it "returns nil when the photo has no 44-digit chave" do
    expect(described_class.digits("VALOR TOTAL R$ 155,00")).to be_nil
  end
end
