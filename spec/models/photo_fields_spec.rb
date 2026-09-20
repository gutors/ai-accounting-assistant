require "rails_helper"

RSpec.describe PhotoFields, type: :model do
  def ocr_fixture(name)
    Rails.root.join("spec/fixtures/files/ocr", name).binread
  end

  it "Real PNG returns 15500 2026-05-11 Padaria Central" do
    png = ocr_fixture("danfe_fields.png")

    result = PhotoFields::Real.new.read(bytes: png, filename: "danfe.png")

    expect(result).to be_a(PhotoFields::Fields)
    expect(result.amount_cents).to eq(15500)
    expect(result.document_on).to eq(Date.new(2026, 5, 11))
    expect(result.payee).to eq("Padaria Central")
  end

  it "Real JPEG returns 15500 2026-05-11 Padaria Central" do
    jpeg = ocr_fixture("danfe_fields.jpg")

    result = PhotoFields::Real.new.read(bytes: jpeg, filename: "danfe.jpg")

    expect(result).to be_a(PhotoFields::Fields)
    expect(result.amount_cents).to eq(15500)
    expect(result.document_on).to eq(Date.new(2026, 5, 11))
    expect(result.payee).to eq("Padaria Central")
  end

  it "Real amount_cents 15500 is Integer" do
    png = ocr_fixture("danfe_fields.png")

    result = PhotoFields::Real.new.read(bytes: png, filename: "danfe.png")

    expect(result.amount_cents).to eq(15500)
    expect(result.amount_cents).to be_a(Integer)
    expect(result.amount_cents).not_to be_a(Float)
  end

  it "Real PNG without amount date emitente returns Miss" do
    png = ocr_fixture("blank.png")

    result = PhotoFields::Real.new.read(bytes: png, filename: "blank.png")

    expect(result).to be_a(PhotoFields::Miss)
  end

  it "Real PNG with only amount is not a complete triple" do
    png = ocr_fixture("amount_only.png")

    result = PhotoFields::Real.new.read(bytes: png, filename: "amount.png")

    complete = result.is_a?(PhotoFields::Fields) &&
      result.amount_cents.present? && result.document_on.present? && result.payee.present?
    expect(complete).to be(false)
  end

  it "Real read misses when tesseract binary is missing" do
    PhotoOcr.binary = "/nonexistent/tesseract-missing-for-spec"
    png = ocr_fixture("danfe_fields.png")

    result = PhotoFields::Real.new.read(bytes: png, filename: "danfe.png")

    expect(result).to be_a(PhotoFields::Miss)
  end

  it "Real read misses when tesseract subprocess errors" do
    PhotoOcr.binary = "/bin/false"
    png = ocr_fixture("danfe_fields.png")

    result = PhotoFields::Real.new.read(bytes: png, filename: "danfe.png")

    expect(result).to be_a(PhotoFields::Miss)
  end
end
