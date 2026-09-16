require "rails_helper"

RSpec.describe Organization, type: :model do
  it "persists trimmed accountant presentation name" do
    organization = Organization.create!(name: "ONG")

    expect(organization.update_accountant(presentation_name: "  Ana Contábil  ")).to be(true)
    expect(organization.accountant_presentation_name).to eq("Ana Contábil")
  end

  it "persists CNPJ digits and razao social" do
    organization = Organization.create!(name: "ONG")

    expect(organization.update_accountant(
      presentation_name: "Ana",
      tax_id: "11.222.333/0001-81",
      legal_name: "  Contábil LTDA  "
    )).to be(true)
    expect(organization.accountant_tax_id).to eq("11222333000181")
    expect(organization.accountant_legal_name).to eq("Contábil LTDA")
  end

  it "persists CPF digits and no razao social" do
    organization = Organization.create!(name: "ONG")

    expect(organization.update_accountant(presentation_name: "Ana", tax_id: "390.533.447-05")).to be(true)
    expect(organization.accountant_tax_id).to eq("39053344705")
    expect(organization.accountant_legal_name).to be_nil
  end

  it "persists destination email via NormalizedEmail" do
    organization = Organization.create!(name: "ONG")

    expect(organization.update_accountant(presentation_name: "Ana", destination_email: "Coord@Example.COM")).to be(true)
    expect(organization.package_destination_email).to eq("coord@example.com")
  end

  it "persists PIX of 1 and 77 characters" do
    organization = Organization.create!(name: "ONG")

    expect(organization.update_accountant(presentation_name: "Ana", pix_key: "x")).to be(true)
    expect(organization.accountant_pix_key).to eq("x")

    seventy_seven = "p" * 77
    expect(organization.update_accountant(presentation_name: "Ana", pix_key: seventy_seven)).to be(true)
    expect(organization.accountant_pix_key).to eq(seventy_seven)
  end

  it "blank optional accountant fields clear them" do
    organization = Organization.create!(name: "ONG")
    organization.update_accountant(
      presentation_name: "Ana",
      tax_id: "11.222.333/0001-81",
      legal_name: "Contábil LTDA",
      pix_key: "chave",
      destination_email: "ana@example.com"
    )

    expect(organization.update_accountant(presentation_name: "Ana")).to be(true)
    expect(organization.accountant_tax_id).to be_nil
    expect(organization.accountant_legal_name).to be_nil
    expect(organization.accountant_pix_key).to be_nil
    expect(organization.package_destination_email).to be_nil
  end

  it "rejects satellite accountant fields without presentation name" do
    [
      { tax_id: "39053344705" },
      { legal_name: "Contábil LTDA" },
      { pix_key: "x" },
      { destination_email: "ana@example.com" }
    ].each do |attrs|
      organization = Organization.create!(name: "ONG")
      expect(organization.update_accountant(attrs)).to be(false)
      organization.reload
      expect(organization.accountant_tax_id).to be_nil
      expect(organization.accountant_legal_name).to be_nil
      expect(organization.accountant_pix_key).to be_nil
      expect(organization.package_destination_email).to be_nil
    end
  end

  it "rejects tax id length and check digits" do
    organization = Organization.create!(name: "ONG")
    organization.update_accountant(presentation_name: "Ana")

    [
      "1234567890",
      "39053344700",
      "11222333000180"
    ].each do |tax_id|
      expect(organization.update_accountant(presentation_name: "Ana", tax_id: tax_id)).to be(false)
      expect(organization.reload.accountant_tax_id).to be_nil
    end
  end

  it "rejects CNPJ without razao social" do
    organization = Organization.create!(name: "ONG")
    organization.update_accountant(presentation_name: "Ana")

    expect(organization.update_accountant(presentation_name: "Ana", tax_id: "11222333000181")).to be(false)
    expect(organization.reload.accountant_tax_id).to be_nil
  end

  it "rejects CPF with razao social" do
    organization = Organization.create!(name: "ONG")
    organization.update_accountant(presentation_name: "Ana")

    expect(organization.update_accountant(
      presentation_name: "Ana",
      tax_id: "39053344705",
      legal_name: "Não deveria"
    )).to be(false)
    expect(organization.reload.accountant_tax_id).to be_nil
    expect(organization.accountant_legal_name).to be_nil
  end

  it "rejects destination that fails NormalizedEmail" do
    organization = Organization.create!(name: "ONG")
    organization.update_accountant(presentation_name: "Ana", destination_email: "ana@example.com")

    expect(organization.update_accountant(presentation_name: "Ana", destination_email: "not-an-email")).to be(false)
    expect(organization.reload.package_destination_email).to eq("ana@example.com")
  end

  it "persists Drive folders URL and extracted folder id" do
    organization = Organization.create!(name: "ONG")
    url = "https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl"

    expect(organization.update_package_archive(url)).to be(true)
    expect(organization.package_archive_url).to eq(url)
    expect(organization.package_archive_folder_id).to eq("15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl")
  end

  it "extracts folder id from drive/u/0/folders URL with query" do
    organization = Organization.create!(name: "ONG")
    url = "https://drive.google.com/drive/u/0/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl?usp=sharing"

    expect(organization.update_package_archive(url)).to be(true)
    expect(organization.package_archive_folder_id).to eq("15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl")
  end

  it "blank archive URL clears url and folder id" do
    organization = Organization.create!(name: "ONG")
    organization.update_package_archive("https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl")

    expect(organization.update_package_archive("")).to be(true)
    expect(organization.package_archive_url).to be_nil
    expect(organization.package_archive_folder_id).to be_nil
  end

  it "rejects http, wrong host, and missing folders segment" do
    organization = Organization.create!(name: "ONG")
    good = "https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl"
    organization.update_package_archive(good)

    [
      "http://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl",
      "https://example.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl",
      "https://drive.google.com/drive/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl"
    ].each do |url|
      expect(organization.update_package_archive(url)).to be(false)
      organization.reload
      expect(organization.package_archive_url).to eq(good)
      expect(organization.package_archive_folder_id).to eq("15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl")
    end
  end

  it "rejects Drive file URL" do
    organization = Organization.create!(name: "ONG")
    good = "https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl"
    organization.update_package_archive(good)

    expect(organization.update_package_archive("https://drive.google.com/file/d/0B_NiLAzvehC9R2stRmQyM3ZiVjQ/view")).to be(false)
    organization.reload
    expect(organization.package_archive_url).to eq(good)
  end
end
