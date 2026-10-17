module PhotoFields
  Fields = Data.define(:amount_cents, :document_on, :payee)
  Miss = Data.define
  AMOUNT = /(\d{1,3}(?:\.\d{3})*,\d{2}|\d+,\d{2})/

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

    def read(bytes:, filename:, text: nil)
      @results.fetch(filename) { Miss.new }
    end
  end

  class Real
    def read(bytes:, filename: nil, text: nil)
      text = PhotoOcr.resolve(bytes, text)
      amount_cents = parse_amount(text)
      document_on = parse_date(text)
      payee = parse_emitente(text, bytes)
      return Miss.new if amount_cents.nil? && document_on.nil? && payee.nil?

      Fields.new(amount_cents:, document_on:, payee:)
    end

    private

    def parse_amount(text)
      match = text.match(/Valor a Pagar\s+R\$?\s*#{AMOUNT}/i) ||
        text.match(/VALOR TOTAL\s+R\$\s*#{AMOUNT}/i) ||
        text.match(/R\$\s*#{AMOUNT}/)
      return if match.nil?

      cents = BrlCents.parse(match[1])
      cents if cents.is_a?(Integer) && cents.positive?
    end

    def parse_date(text)
      match = text.match(%r{(\d{2})/(\d{2})/(\d{4})})
      match ||= text.match(%r{(\d{2})/(\d{2})/(\d{2})(?!\d)})
      return if match.nil?

      year = match[3].to_i
      year += 2000 if year < 100
      Date.new(year, match[2].to_i, match[1].to_i)
    rescue Date::Error
      nil
    end

    def parse_emitente(text, bytes)
      section = text[/EMITENTE\s+(.+?)\s+DESTINAT/im, 1]
      name = cleaned_line(section)
      return name if name.present?

      cupom = text.match?(/Documento\s+\S+.*?Consumidor/im)
      if cupom
        from_header = cleaned_line(PhotoOcr.header(bytes))
        return from_header if company_line?(from_header)
      end

      header = text.split(/Documento\s+\S+.*?Consumidor/im).first
      return if header.blank? || header == text

      header.lines.map { |line| cleaned_line(line) }.find { |line| company_line?(line) }
    end

    def cleaned_line(text)
      return if text.blank?

      text.lines.map { |line|
        tokens = line.gsub(/[^A-Za-z0-9À-ÿ ]/, " ").split
        joined = tokens.drop_while { |token| token.length <= 2 || token.match?(/\A\d+\z/) }.join(" ")
        next if joined.blank?

        ActiveSupport::Inflector.transliterate(joined).strip
      }.find { |line| line.match?(/[A-Za-z]{3,}/) }
    end

    def company_line?(line)
      return false if line.blank?
      return false if line.match?(/\A(RUA|AV|AVENIDA|ALAMEDA|TRAVESSA|PORTO|CIDADE)\b/i)

      line.match?(/[A-Za-zÀ-ÿ].*[A-Za-zÀ-ÿ]/)
    end
  end
end
