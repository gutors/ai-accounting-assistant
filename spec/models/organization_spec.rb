require "rails_helper"

RSpec.describe Organization, type: :model do
  include ActiveSupport::Testing::TimeHelpers

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

  it "install pfx persists titular 11222333000181 and notAfter 2027-09-18" do
    organization = Organization.create!(name: "ONG")

    expect(organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")).to be(true)
    expect(organization.sefaz_titular_cnpj).to eq("11222333000181")
    expect(organization.sefaz_not_after).to eq(Date.new(2027, 9, 18))
    pkcs12 = organization.unwrap_sefaz_pkcs12
    expect(pkcs12).to be_a(OpenSSL::PKCS12)
  end

  it "install p12 persists titular 11222333000181" do
    organization = Organization.create!(name: "ONG")

    expect(organization.install_sefaz_certificate(file: sefaz_p12, passphrase: "passphrase-secreta")).to be(true)
    expect(organization.sefaz_titular_cnpj).to eq("11222333000181")
  end

  it "install with passphrase errada persists no certificate" do
    organization = Organization.create!(name: "ONG")

    expect(organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "errada")).to be(false)
    expect(organization.errors[:base]).to include("Não foi possível abrir o certificado com essa senha")
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "install e-CPF 39053344705 persists no certificate" do
    organization = Organization.create!(name: "ONG")

    expect(organization.install_sefaz_certificate(
      file: sefaz_pfx(titular: "39053344705"),
      passphrase: "passphrase-secreta"
    )).to be(false)
    expect(organization.errors[:base]).to include("O certificado deve ser e-CNPJ A1 vigente")
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "install notAfter 2026-05-10 on 2026-05-11 persists no certificate" do
    organization = Organization.create!(name: "ONG")

    travel_to Date.new(2026, 5, 11) do
      expect(organization.install_sefaz_certificate(
        file: sefaz_pfx(not_after: Date.new(2026, 5, 10)),
        passphrase: "passphrase-secreta"
      )).to be(false)
    end
    expect(organization.errors[:base]).to include("O certificado deve ser e-CNPJ A1 vigente")
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "install txt persists no certificate" do
    organization = Organization.create!(name: "ONG")

    expect(organization.install_sefaz_certificate(
      file: sefaz_txt_certificate,
      passphrase: "passphrase-secreta"
    )).to be(false)
    expect(organization.errors[:base]).to include("O certificado deve ser e-CNPJ A1 vigente")
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "install larger than 1048576 persists no certificate" do
    organization = Organization.create!(name: "ONG")

    expect(organization.install_sefaz_certificate(
      file: oversized_sefaz_pfx,
      passphrase: "passphrase-secreta"
    )).to be(false)
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "install second A1 replaces titular 12345678000101" do
    organization = Organization.create!(name: "ONG")
    organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")

    expect(organization.install_sefaz_certificate(
      file: sefaz_pfx(titular: "12345678000101", passphrase: "outrasenha", name: "other.pfx"),
      passphrase: "outrasenha"
    )).to be(true)
    expect(organization.sefaz_titular_cnpj).to eq("12345678000101")
    expect(organization.sefaz_titular_cnpj).not_to eq("11222333000181")
    pkcs12 = organization.unwrap_sefaz_pkcs12
    expect(pkcs12).to be_a(OpenSSL::PKCS12)
  end

  it "remove_sefaz_certificate nulls the slot" do
    organization = Organization.create!(name: "ONG")
    organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")

    organization.remove_sefaz_certificate

    expect(organization.sefaz_titular_cnpj).to be_nil
    expect(organization.sefaz_not_after).to be_nil
    expect(organization.sefaz_pkcs12_ciphertext).to be_nil
    expect(organization.sefaz_passphrase_ciphertext).to be_nil
  end

  it "install with blank wrap key persists no certificate" do
    organization = Organization.create!(name: "ONG")

    with_env("SEFAZ_WRAP_KEY" => nil) do
      expect(organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")).to be(false)
    end
    expect(organization.errors[:base]).to include("O certificado não pôde ser guardado")
    expect(organization.reload.sefaz_titular_cnpj).to be_nil
  end

  it "install while a month is closed still persists" do
    organization = Organization.create!(name: "ONG")
    month, _statement = plant_month(organization)
    month.update!(closed: true)

    expect(organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")).to be(true)
    expect(organization.sefaz_titular_cnpj).to eq("11222333000181")
  end

  describe "concurrent A1 installs leave one consistent pair" do
    self.use_transactional_tests = false

    it "concurrent A1 installs leave one consistent pair" do
      truncate_product_tables
      organization = Organization.create!(name: "ONG")
      first = sefaz_pfx(titular: "11222333000181", passphrase: "senha-a", name: "a.pfx")
      second = sefaz_pfx(titular: "12345678000101", passphrase: "senha-b", name: "b.pfx")
      queue = Queue.new
      queue << [ first, "senha-a" ]
      queue << [ second, "senha-b" ]

      run_in_parallel(2) do
        file, passphrase = queue.pop
        Organization.find(organization.id).install_sefaz_certificate(file:, passphrase:)
      end

      organization.reload
      expect(Organization.where(id: organization.id).where.not(sefaz_titular_cnpj: nil).count).to eq(1)
      expect(%w[11222333000181 12345678000101]).to include(organization.sefaz_titular_cnpj)
      expect(organization.unwrap_sefaz_pkcs12).to be_a(OpenSSL::PKCS12)
    ensure
      truncate_product_tables
    end
  end
end
