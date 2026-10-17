require "rails_helper"

RSpec.describe AuthorizedNfe, type: :model do
  it "parse NFCom 25680 EMPRESA TELECOM 2026-06-15 chave" do
    parsed = described_class.parse(authorized_nfcom_xml)

    expect(parsed.amount_cents).to eq(25680)
    expect(parsed.payee).to eq("EMPRESA TELECOM EXEMPLO S.A.")
    expect(parsed.document_on).to eq(Date.new(2026, 6, 15))
    expect(parsed.chave).to eq("27260611222333000181620010008920781028142810")
  end

  it "parse NF3e 18940 Companhia Energetica 2026-05-20 chave" do
    parsed = described_class.parse(authorized_nf3e_xml)

    expect(parsed.amount_cents).to eq(18940)
    expect(parsed.payee).to eq("Companhia Energetica Exemplo")
    expect(parsed.document_on).to eq(Date.new(2026, 5, 20))
    expect(parsed.chave).to eq("27260611222333000181660010000008920781028142")
  end

  it "parse national NFSe 61000 Contabilidade Exemplo 2026-05-06 chave" do
    parsed = described_class.parse(authorized_nfse_xml)

    expect(parsed.amount_cents).to eq(61000)
    expect(parsed.payee).to eq("Contabilidade Exemplo Ltda")
    expect(parsed.document_on).to eq(Date.new(2026, 5, 6))
    expect(parsed.chave).to eq("41260511222333000181000000000000000000000000000001")
  end

  it "parse NFe 15500 Padaria Central 2026-05-11 chave" do
    parsed = described_class.parse(authorized_nfe_xml)

    expect(parsed.amount_cents).to eq(15500)
    expect(parsed.payee).to eq("Padaria Central")
    expect(parsed.document_on).to eq(Date.new(2026, 5, 11))
    expect(parsed.chave).to eq("43260511222333000181550010000000011123456781")
  end

  it "parse malformed XML is nil and not unsupported" do
    bytes = "<nfe><"

    expect(described_class.parse(bytes)).to be_nil
    expect(described_class.unsupported?(bytes)).to eq(false)
  end

  it "parse infNFe without vNF is nil and not unsupported" do
    bytes = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <nfeProc xmlns="http://www.portalfiscal.inf.br/nfe">
        <NFe>
          <infNFe Id="NFe43260511222333000181550010000000011123456781">
            <ide><dhEmi>2026-05-11T10:00:00-03:00</dhEmi></ide>
            <emit><xNome>Padaria Central</xNome></emit>
          </infNFe>
        </NFe>
      </nfeProc>
    XML

    expect(described_class.parse(bytes)).to be_nil
    expect(described_class.unsupported?(bytes)).to eq(false)
  end

  it "unsupported other DFe roots" do
    %w[infCte infCteOS infMDFe infBPe infNFAg infNFGas CFe infCFe].each do |name|
      bytes = %(<doc xmlns="http://example.org"><#{name} Id="x"></#{name}></doc>)

      expect(described_class.parse(bytes)).to be_nil
      expect(described_class.unsupported?(bytes)).to eq(true), name
    end

    expect(described_class.parse(cte_xml)).to be_nil
    expect(described_class.unsupported?(cte_xml)).to eq(true)
    expect(described_class.parse(municipal_nfse_xml)).to be_nil
    expect(described_class.unsupported?(municipal_nfse_xml)).to eq(true)
  end
end
