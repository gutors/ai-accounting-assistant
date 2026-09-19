require "net/http"

module PublicNfceConsulta
  Fields = Data.define(:amount_cents, :payee, :document_on)
  Miss = Data.define
  Error = Data.define

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

    def allowed?(url)
      uri = URI.parse(url)
      return false unless uri.is_a?(URI::HTTPS)
      return false if uri.userinfo.present?

      host = uri.host.to_s.downcase
      return false if host.empty? || host.include?(":")
      return false unless host == "gov.br" || host.end_with?(".gov.br")

      query = URI.decode_www_form(uri.query.to_s).to_h
      p = query["p"].to_s
      tp_amb = p.split("|")[2]
      tp_amb != "2"
    rescue URI::InvalidURIError, ArgumentError
      false
    end
  end

  class Fake
    def initialize
      @results = {}
    end

    def set(url, result)
      @results[url] = result
    end

    def fetch(url)
      return Miss.new unless PublicNfceConsulta.allowed?(url)

      @results.fetch(url) { Miss.new }
    end
  end

  class Real
    def fetch(url)
      return Miss.new unless PublicNfceConsulta.allowed?(url)

      html = get(url)
      parse(html)
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError, OpenSSL::SSL::SSLError
      Error.new
    end

    private

    def get(url)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 15
      http.read_timeout = 30
      request = Net::HTTP::Get.new(uri.request_uri)
      http.request(request).body
    end

    def parse(html)
      doc = Nokogiri::HTML(html)
      amount_cents = BrlCents.parse(text_after(doc, /valor|vNF/i) || vnf_node(doc))
      payee = emitente_name(doc)
      document_on = parse_date(text_after(doc, /emiss[aã]o|dhEmi|data/i))
      return Miss.new if amount_cents.nil? || payee.blank? || document_on.nil?

      Fields.new(amount_cents:, payee:, document_on:)
    end

    def vnf_node(doc)
      doc.at_xpath("//*[local-name()='vNF']")&.text
    end

    def emitente_name(doc)
      label = doc.at_xpath("//*[contains(translate(., 'EMITENTE', 'emitente'), 'emitente')]")
      sibling = label&.parent&.text.to_s
      name = sibling[/\bemitente\b[:\s]*([^\n]+)/i, 1].to_s.strip
      name.presence || doc.at_xpath("//*[local-name()='xNome']")&.text&.strip
    end

    def text_after(doc, pattern)
      node = doc.css("*").find { |el| el.text.match?(pattern) && el.css("*").empty? }
      node&.parent&.text
    end

    def parse_date(text)
      return if text.blank?

      digits = text[/\d{4}-\d{2}-\d{2}/]
      return Date.iso8601(digits) if digits

      br = text[/(\d{2})\/(\d{2})\/(\d{4})/]
      Date.new(Regexp.last_match(3).to_i, Regexp.last_match(2).to_i, Regexp.last_match(1).to_i) if br
    rescue ArgumentError, Date::Error
      nil
    end
  end
end
