module PhotoFields
  Fields = Data.define(:amount_cents, :document_on, :payee)
  Miss = Data.define

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

    def set(filename, amount_cents: nil, document_on: nil, payee: nil)
      @results[filename] = Fields.new(amount_cents:, document_on:, payee:)
    end

    def miss(filename)
      @results[filename] = Miss.new
    end

    def read(bytes:, filename:)
      @results.fetch(filename) { Miss.new }
    end
  end

  class Real
    def read(bytes:, filename: nil)
      text = PhotoOcr.text(bytes)
      amount_cents = parse_amount(text)
      document_on = parse_date(text)
      payee = parse_emitente(text)
      return Miss.new if amount_cents.nil? && document_on.nil? && payee.nil?

      Fields.new(amount_cents:, document_on:, payee:)
    end

    private

    def parse_amount(text)
      match = text.match(/R\$\s*(\d{1,3}(?:\.\d{3})*,\d{2}|\d+,\d{2})/)
      return if match.nil?

      cents = BrlCents.parse(match[0])
      cents if cents.is_a?(Integer)
    end

    def parse_date(text)
      match = text.match(%r{(\d{2})/(\d{2})/(\d{4})})
      return if match.nil?

      Date.new(match[3].to_i, match[2].to_i, match[1].to_i)
    rescue Date::Error
      nil
    end

    def parse_emitente(text)
      section = text[/EMITENTE\s+(.+?)\s+DESTINAT/im, 1]
      return if section.blank?

      section.lines.map { |line| line.gsub(/[^A-Za-z0-9 ]/, " ").squeeze(" ").strip }.find(&:present?)
    end
  end
end
