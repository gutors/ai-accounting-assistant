require "rails_helper"

RSpec.describe SefazConsulta, type: :model do
  def gzip_b64(xml)
    Base64.strict_encode64(Zlib.gzip(xml))
  end

  def ret_dist(cstat, doc_zip: nil)
    zip = doc_zip ? "<docZip>#{doc_zip}</docZip>" : ""
    "<retDistDFeInt><cStat>#{cstat}</cStat>#{zip}</retDistDFeInt>"
  end

  it "parse_response 138 with infNFe is Xml" do
    result = SefazConsulta::Real.parse_response(ret_dist("138", doc_zip: gzip_b64(authorized_nfe_xml)))

    expect(result).to be_a(SefazConsulta::Xml)
    parsed = AuthorizedNfe.parse(result.bytes)
    expect(parsed.amount_cents).to eq(15500)
  end

  it "parse_response 138 with resNFe is Resumo" do
    res = "<resNFe><xNome>Padaria Central</xNome><vNF>155.00</vNF><dhEmi>2026-05-11T10:00:00-03:00</dhEmi></resNFe>"
    result = SefazConsulta::Real.parse_response(ret_dist("138", doc_zip: gzip_b64(res)))

    expect(result).to be_a(SefazConsulta::Resumo)
    expect(result.amount_cents).to eq(15500)
    expect(result.payee).to eq("Padaria Central")
    expect(result.document_on).to eq(Date.new(2026, 5, 11))
  end

  it "parse_response 137 is NotFound" do
    expect(SefazConsulta::Real.parse_response(ret_dist("137"))).to be_a(SefazConsulta::NotFound)
  end

  it "parse_response other cStat is Error" do
    expect(SefazConsulta::Real.parse_response(ret_dist("656"))).to be_a(SefazConsulta::Error)
  end
end
