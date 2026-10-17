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
      motivo = xml.at_xpath("//*[local-name()='xMotivo']")&.text
      Rails.logger.info("sefaz_consulta cStat=#{cstat.inspect} xMotivo=#{motivo.inspect}")
      return NotFound.new if cstat == "137"
      return WindowExpired.new if cstat == "632"
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
      request["Content-Type"] = "application/soap+xml; charset=utf-8"
      request["SOAPAction"] = "http://www.portalfiscal.inf.br/nfe/wsdl/NFeDistribuicaoDFe/nfeDistDFeInteresse"
      request.body = dist_dfe_envelope(pkcs12:, chave:)
      http.request(request).body
    end

    def dist_dfe_envelope(pkcs12:, chave:)
      cnpj = cnpj_from(pkcs12)
      dist = +"<distDFeInt xmlns=\"http://www.portalfiscal.inf.br/nfe\" versao=\"1.01\">"
      dist << "<tpAmb>1</tpAmb><CNPJ>#{cnpj}</CNPJ>"
      dist << "<consChNFe><chNFe>#{chave}</chNFe></consChNFe></distDFeInt>"
      +"<soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\"><soap:Body>" \
        "<nfeDistDFeInteresse xmlns=\"http://www.portalfiscal.inf.br/nfe/wsdl/NFeDistribuicaoDFe\">" \
        "<nfeDadosMsg xmlns=\"http://www.portalfiscal.inf.br/nfe/wsdl/NFeDistribuicaoDFe\">#{dist}</nfeDadosMsg>" \
        "</nfeDistDFeInteresse></soap:Body></soap:Envelope>"
    end

    def cnpj_from(pkcs12)
      cert = pkcs12.certificate
      cn = cert.subject.to_a.assoc("CN")&.at(1).to_s
      cn[/:(\d{14})\s*\z/, 1] ||
        cert.subject.to_a.reverse.filter_map { |_, value, _|
          digits = value.to_s.gsub(/\D/, "")
          digits if digits.length == 14
        }.first
    end
  end
end
