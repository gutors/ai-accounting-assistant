require "base64"
require "nokogiri"
require "zlib"
require "net/http"

module SefazConsulta
  Xml = Data.define(:bytes)
  Resumo = Data.define(:amount_cents, :payee, :document_on)
  NotFound = Data.define
  WindowExpired = Data.define
  Error = Data.define

  PRODUCAO_URL = "https://www1.nfe.fazenda.gov.br/NFeDistribuicaoDFe/NFeDistribuicaoDFe.asmx"

  class << self
    def current
      @current ||= build
    end

    def current=(client)
      @current = client
    end

    def reset!
      @current = Fake.new
    end

    def build
      Real.new
    end
  end

  class Fake
    def initialize
      @results = {}
    end

    def set(chave, result)
      @results[chave] = result
    end

    def lookup(pkcs12:, chave:)
      @results.fetch(chave) { Error.new }
    end
  end

  class Real
    def lookup(pkcs12:, chave:)
      self.class.parse_response(post_dist_dfe(pkcs12:, chave:))
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError, OpenSSL::SSL::SSLError
      Error.new
    end

    def self.parse_response(body)
      xml = Nokogiri::XML(body) { |config| config.strict }
      cstat = xml.at_xpath("//*[local-name()='cStat']")&.text
      return NotFound.new if cstat == "137"
      return Error.new unless cstat == "138"

      decoded = unzip_doc(xml)
      return Error.new unless decoded

      if decoded.include?("infNFe")
        Xml.new(decoded)
      else
        resumo_from(decoded) || Error.new
      end
    rescue Nokogiri::XML::SyntaxError
      Error.new
    end

    def self.unzip_doc(xml)
      zip = xml.at_xpath("//*[local-name()='docZip']")&.text
      return if zip.blank?

      Zlib::GzipReader.new(StringIO.new(Base64.decode64(zip))).read
    rescue Zlib::Error, ArgumentError
      nil
    end
    private_class_method :unzip_doc

    def self.resumo_from(decoded)
      node = Nokogiri::XML(decoded)
      res = node.at_xpath("//*[local-name()='resNFe']")
      return unless res

      amount_cents = BrlCents.parse(res.at_xpath(".//*[local-name()='vNF']")&.text)
      payee = res.at_xpath(".//*[local-name()='xNome']")&.text&.strip
      dhemi = res.at_xpath(".//*[local-name()='dhEmi']")&.text.to_s
      document_on = Date.iso8601(dhemi[0, 10])
      return if amount_cents.nil? || payee.blank?

      Resumo.new(amount_cents:, payee:, document_on:)
    rescue ArgumentError, Date::Error
      nil
    end
    private_class_method :resumo_from

    private

    def post_dist_dfe(pkcs12:, chave:)
      uri = URI(PRODUCAO_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.cert = pkcs12.certificate
      http.key = pkcs12.key
      http.open_timeout = 15
      http.read_timeout = 30
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "text/xml; charset=utf-8"
      request.body = dist_dfe_envelope(pkcs12:, chave:)
      http.request(request).body
    end

    def dist_dfe_envelope(pkcs12:, chave:)
      cnpj = pkcs12.certificate.subject.to_s.scan(/\d{14}/).first
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope" xmlns:nfe="http://www.portalfiscal.inf.br/nfe/wsdl/NFeDistribuicaoDFe">
          <soap12:Body>
            <nfe:nfeDistDFeInteresse>
              <nfe:nfeDadosMsg>
                <distDFeInt xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.01">
                  <tpAmb>1</tpAmb>
                  <cUFAutor>91</cUFAutor>
                  <CNPJ>#{cnpj}</CNPJ>
                  <consChNFe>
                    <chNFe>#{chave}</chNFe>
                  </consChNFe>
                </distDFeInt>
              </nfe:nfeDadosMsg>
            </nfe:nfeDistDFeInteresse>
          </soap12:Body>
        </soap12:Envelope>
      XML
    end
  end
end
