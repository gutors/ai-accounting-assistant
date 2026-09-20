require "rails_helper"
require "barby"
require "barby/barcode/code_128"
require "barby/outputter/png_outputter"
require "rqrcode"

RSpec.describe PhotoSymbols, type: :model do
  def nfe_chave
    "43260511222333000181550010000000011123456781"
  end

  def ocr_fixture(name)
    Rails.root.join("spec/fixtures/files/ocr", name).binread
  end

  def nfce_chave
    "43260511222333000181650010000000011123456781"
  end

  def nfce_qr_url
    "https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=#{nfce_chave}|2|1|1"
  end

  it "Real CODE-128 PNG returns chave 43260511222333000181550010000000011123456781" do
    png = Barby::Code128B.new(nfe_chave).to_png(xdim: 2, height: 80, margin: 16)

    result = PhotoSymbols::Real.new.scan(bytes: png, filename: "code128.png")

    expect(result.chave).to eq(nfe_chave)
    expect(result.qr_url).to be_nil
  end

  it "Real QR PNG returns NFC-e chave and sefaz.rs.gov.br URL" do
    png = RQRCode::QRCode.new(nfce_qr_url).as_png(bit_depth: 1, border_modules: 4, module_px_size: 6).to_s

    result = PhotoSymbols::Real.new.scan(bytes: png, filename: "qr.png")

    expect(result.chave).to eq(nfce_chave)
    expect(result.qr_url).to eq(nfce_qr_url)
  end

  it "Real printed-digit PNG returns chave 43260511222333000181550010000000011123456781" do
    png = ocr_fixture("printed_chave.png")

    result = PhotoSymbols::Real.new.scan(bytes: png, filename: "printed.png")

    expect(result.chave).to eq(nfe_chave)
    expect(result.qr_url).to be_nil
  end

  it "Real printed-digit JPEG returns chave 43260511222333000181550010000000011123456781" do
    jpeg = ocr_fixture("printed_chave.jpg")

    result = PhotoSymbols::Real.new.scan(bytes: jpeg, filename: "printed.jpg")

    expect(result.chave).to eq(nfe_chave)
    expect(result.qr_url).to be_nil
  end

  it "Real printed-digit PNG without 44 digits returns chave nil" do
    png = ocr_fixture("blank.png")

    result = PhotoSymbols::Real.new.scan(bytes: png, filename: "blank-chave.png")

    expect(result.chave).to be_nil
  end

  it "Real scan misses when tesseract binary is missing" do
    PhotoOcr.binary = "/nonexistent/tesseract-missing-for-spec"
    png = ocr_fixture("printed_chave.png")

    result = PhotoSymbols::Real.new.scan(bytes: png, filename: "printed.png")

    expect(result.chave).to be_nil
  end

  it "Real scan misses when tesseract subprocess errors" do
    PhotoOcr.binary = "/bin/false"
    png = ocr_fixture("printed_chave.png")

    result = PhotoSymbols::Real.new.scan(bytes: png, filename: "printed.png")

    expect(result.chave).to be_nil
  end
end
