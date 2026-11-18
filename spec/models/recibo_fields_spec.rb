require "rails_helper"

RSpec.describe ReciboFields, type: :model do
  it "Real Padaria recibo PDF is 15500 2026-06-15 Padaria Central Integer" do
    result = ReciboFields::Real.new.read(bytes: text_pdf(padaria_recibo_text), filename: "padaria-recibo.pdf")

    expect(result).to be_a(ReciboFields::Fields)
    expect(result.amount_cents).to eq(15500)
    expect(result.amount_cents).to be_a(Integer)
    expect(result.amount_cents).not_to be_a(Float)
    expect(result.document_on).to eq(Date.new(2026, 6, 15))
    expect(result.payee).to eq("Padaria Central")
  end

  it "Real Kali recibo PDF is 29500 2026-06-27 Kali Confeitaria not payer" do
    result = ReciboFields::Real.new.read(bytes: text_pdf(kali_recibo_text), filename: "kali-recibo.pdf")

    expect(result).to be_a(ReciboFields::Fields)
    expect(result.amount_cents).to eq(29500)
    expect(result.document_on).to eq(Date.new(2026, 6, 27))
    expect(result.payee).to eq("Kali Confeitaria")
    expect(result.payee).not_to eq("Centro Social da Rua")
    expect(result.payee).not_to include("Centro Social")
  end

  it "Real amount-only PDF returns Miss" do
    result = ReciboFields::Real.new.read(bytes: text_pdf("R$ 155,00"), filename: "amount-only.pdf")

    expect(result).to be_a(ReciboFields::Miss)
  end

  it "Real DANFE PDF without RECIBO title returns Miss" do
    text = <<~TEXT
      EMITENTE
      Padaria Central
      VALOR TOTAL DA NOTA R$ 155,00
      11/05/2026
    TEXT

    result = ReciboFields::Real.new.read(bytes: text_pdf(text), filename: "danfe.pdf")

    expect(result).to be_a(ReciboFields::Miss)
  end

  it "Real app receipt PDF returns Miss" do
    text = <<~TEXT
      Aqui está o recibo da sua entrega
      Total R$ 40,94
      Preço da viagem R$ 39,23
    TEXT

    result = ReciboFields::Real.new.read(bytes: text_pdf(text), filename: "uber.pdf")

    expect(result).to be_a(ReciboFields::Miss)
  end

  it "Real pdftotext Padaria triple does not call PhotoOcr" do
    expect(PhotoOcr).not_to receive(:text)

    result = ReciboFields::Real.new.read(bytes: text_pdf(padaria_recibo_text), filename: "padaria-recibo.pdf")

    expect(result).to be_a(ReciboFields::Fields)
    expect(result.amount_cents).to eq(15500)
    expect(result.document_on).to eq(Date.new(2026, 6, 15))
    expect(result.payee).to eq("Padaria Central")
  end

  it "Real empty pdftotext uses OCR Padaria triple" do
    pdf = text_pdf("blank")
    allow(PhotoPdf).to receive(:text).and_return("")
    allow(PhotoPdf).to receive(:png_pages).and_return([ "png-bytes" ])
    allow(PhotoOcr).to receive(:text).with("png-bytes").and_return(padaria_recibo_text)

    result = ReciboFields::Real.new.read(bytes: pdf, filename: "scan.pdf")

    expect(result).to be_a(ReciboFields::Fields)
    expect(result.amount_cents).to eq(15500)
    expect(result.document_on).to eq(Date.new(2026, 6, 15))
    expect(result.payee).to eq("Padaria Central")
  end
end
