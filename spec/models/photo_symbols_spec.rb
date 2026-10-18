require "rails_helper"
require "barby"
require "barby/barcode/code_128"
require "barby/outputter/png_outputter"
require "chunky_png"
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

  def code128_png
    Barby::Code128B.new(nfe_chave).to_png(xdim: 2, height: 80, margin: 16)
  end

  it "Real CODE-128 PNG returns chave 43260511222333000181550010000000011123456781" do
    result = PhotoSymbols::Real.new.scan(bytes: code128_png, filename: "code128.png")

    expect(result.chave).to eq(nfe_chave)
    expect(result.qr_url).to be_nil
  end

  it "Real CODE-128 JPEG returns chave 43260511222333000181550010000000011123456781" do
    jpeg = ocr_fixture("code128_progressive.jpg")

    result = PhotoSymbols::Real.new.scan(bytes: jpeg, filename: "code128.jpg")

    expect(result.chave).to eq(nfe_chave)
    expect(result.qr_url).to be_nil
  end

  it "Real CODE-128 below midline PNG returns chave 43260511222333000181550010000000011123456781" do
    bar = ChunkyPNG::Image.from_blob(code128_png)
    canvas = ChunkyPNG::Image.new(bar.width, bar.height * 4, ChunkyPNG::Color::WHITE)
    canvas.compose!(bar, 0, bar.height * 3)

    result = PhotoSymbols::Real.new.scan(bytes: canvas.to_blob, filename: "code128-low.png")

    expect(result.chave).to eq(nfe_chave)
    expect(result.qr_url).to be_nil
  end

  it "Real JPEG CODE-128 survives PureJPEG DecodeError" do
    jpeg = ocr_fixture("code128_progressive.jpg")
    allow(PureJPEG).to receive(:read).and_raise(PureJPEG::DecodeError, "spec")

    result = PhotoSymbols::Real.new.scan(bytes: jpeg, filename: "code128.jpg")

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

  it "Real CODE-128 PDF returns chave 43260511222333000181550010000000011123456781" do
    result = PhotoSymbols::Real.new.scan(bytes: pngs_to_pdf(code128_png), filename: "code128.pdf")

    expect(result.chave).to eq(nfe_chave)
    expect(result.qr_url).to be_nil
  end

  it "Real printed-digit PDF returns chave 43260511222333000181550010000000011123456781" do
    result = PhotoSymbols::Real.new.scan(bytes: pngs_to_pdf(ocr_png("printed_chave.png")), filename: "printed.pdf")

    expect(result.chave).to eq(nfe_chave)
    expect(result.qr_url).to be_nil
  end

  it "Real blank PDF returns chave nil" do
    result = PhotoSymbols::Real.new.scan(bytes: pngs_to_pdf(ocr_png("blank.png")), filename: "blank.pdf")

    expect(result.chave).to be_nil
  end

  it "Real two-page PDF blank then CODE-128 returns first delivering chave" do
    pdf = pngs_to_pdf(ocr_png("blank.png"), code128_png)

    result = PhotoSymbols::Real.new.scan(bytes: pdf, filename: "later.pdf")

    expect(result.chave).to eq(nfe_chave)
  end

  it "Real two-page PDF two CODE-128 returns first page chave" do
    page2 = Barby::Code128B.new(other_chave).to_png(xdim: 2, height: 80, margin: 16)
    pdf = pngs_to_pdf(code128_png, page2)

    result = PhotoSymbols::Real.new.scan(bytes: pdf, filename: "first.pdf")

    expect(result.chave).to eq(nfe_chave)
  end

  it "Real scan misses when pdftoppm binary is missing" do
    PhotoPdf.binary = "/nonexistent/pdftoppm-missing-for-spec"
    pdf = pngs_to_pdf(code128_png)

    result = PhotoSymbols::Real.new.scan(bytes: pdf, filename: "code128.pdf")

    expect(result.chave).to be_nil
  end

  it "Real scan misses when pdftoppm subprocess errors" do
    PhotoPdf.binary = "/bin/false"
    pdf = pngs_to_pdf(code128_png)

    result = PhotoSymbols::Real.new.scan(bytes: pdf, filename: "code128.pdf")

    expect(result.chave).to be_nil
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
