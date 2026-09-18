require "openssl"

module Pkcs12Helpers
  DER = {}

  def sefaz_pfx(titular: "11222333000181", not_after: Date.new(2027, 9, 18), passphrase: "passphrase-secreta", name: "cert.pfx")
    upload_path(name, sefaz_pkcs12_der(titular:, not_after:, passphrase:), "application/x-pkcs12")
  end

  def sefaz_p12(**attrs)
    sefaz_pfx(**attrs, name: attrs[:name] || "cert.p12")
  end

  def sefaz_pkcs12_der(titular:, not_after:, passphrase:)
    key = [ titular, not_after.iso8601, passphrase ]
    DER[key] ||= build_pkcs12_der(titular:, not_after:, passphrase:)
  end

  def oversized_sefaz_pfx
    upload_path("huge.pfx", "x" * 1_048_577, "application/x-pkcs12")
  end

  def sefaz_txt_certificate
    upload_path("cert.txt", "not-a-pkcs12", "text/plain")
  end

  private

  def build_pkcs12_der(titular:, not_after:, passphrase:)
    key = OpenSSL::PKey::RSA.new(2048)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    cert.subject = OpenSSL::X509::Name.parse("/CN=#{titular}")
    cert.issuer = cert.subject
    cert.not_before = Time.utc(2020, 1, 1)
    cert.not_after = Time.utc(not_after.year, not_after.month, not_after.day, 23, 59, 59)
    cert.public_key = key.public_key
    cert.sign(key, OpenSSL::Digest::SHA256.new)
    OpenSSL::PKCS12.create(passphrase, "sefaz", key, cert).to_der
  end
end
