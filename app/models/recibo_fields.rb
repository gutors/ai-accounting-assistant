module ReciboFields
  Fields = Data.define(:amount_cents, :document_on, :payee)
  Miss = Data.define
  AMOUNT = /(\d{1,3}(?:\.\d{3})*,\d{2}|\d+,\d{2})/
  MONTHS = {
    "janeiro" => 1, "fevereiro" => 2, "marco" => 3, "março" => 3,
    "abril" => 4, "maio" => 5, "junho" => 6, "julho" => 7,
    "agosto" => 8, "setembro" => 9, "outubro" => 10, "novembro" => 11, "dezembro" => 12
  }.freeze

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
      extracted = text.presence || PhotoPdf.text(bytes)
      if extracted.present?
        result = parse(extracted)
        return result if complete?(result)
        return Miss.new if danfe?(extracted) || app_receipt?(extracted)
      end

      pages = PhotoPdf.png_pages(bytes)
      return Miss.new if pages.blank?

      leftover = nil
      pages.each do |png|
        result = parse(PhotoOcr.text(png))
        return result if complete?(result)

        leftover = result if result.is_a?(Fields)
      end
      leftover || Miss.new
    end

    private

    def parse(text)
      return Miss.new if text.blank?
      return Miss.new if app_receipt?(text)
      return Miss.new if danfe?(text)

      amount_cents = parse_amount(text)
      document_on = parse_date(text)
      payee = parse_payee(text)
      return Miss.new unless complete_values?(amount_cents, document_on, payee)

      Fields.new(amount_cents:, document_on:, payee:)
    end

    def complete?(result)
      result.is_a?(Fields) && complete_values?(result.amount_cents, result.document_on, result.payee)
    end

    def complete_values?(amount_cents, document_on, payee)
      amount_cents.is_a?(Integer) && amount_cents.positive? && document_on.present? && payee.present?
    end

    def app_receipt?(text)
      text.match?(/recibo da sua entrega/i) || text.match?(/Preço da viagem/i)
    end

    def danfe?(text)
      text.match?(/EMITENTE/i) && text.match?(/VALOR TOTAL DA NOTA/i)
    end

    def parse_amount(text)
      match = text.match(/a quantia de\s+R\$\s*#{AMOUNT}/i) ||
        text.match(/o valor de\s+R\$\s*#{AMOUNT}/i) ||
        text.match(/R\$\s*#{AMOUNT}/)
      return if match.nil?

      cents = BrlCents.parse(match[1])
      cents if cents.is_a?(Integer) && cents.positive?
    end

    def parse_date(text)
      numeric = text.match(%r{(\d{1,2})\s*/\s*(\d{1,2})\s*/\s*(\d{2,4})})
      if numeric
        year = numeric[3].to_i
        year += 2000 if year < 100
        return Date.new(year, numeric[2].to_i, numeric[1].to_i)
      end

      written = text.match(/(\d{1,2})\s+de\s+([A-Za-zÀ-ÿ]+)\s+de\s+(\d{4})/i)
      return if written.nil?

      month = MONTHS[ActiveSupport::Inflector.transliterate(written[2]).downcase]
      return if month.nil?

      Date.new(written[3].to_i, month, written[1].to_i)
    rescue Date::Error
      nil
    end

    def parse_payee(text)
      payer = payer_name(text)
      from_eu = text[/Eu\s+(.+?),\s*portador/i, 1]
      name = clean_payee(from_eu)
      return name if usable_payee?(name, payer)

      text.lines.filter_map { |line| clean_payee(line) }.find { |line| usable_payee?(line, payer) }
    end

    def payer_name(text)
      raw = text[/Recebi(?:\s+de|\s+do)\s+([^,\n\-]+)/i, 1] ||
        text[/recebido d[eo]\s+([^,\n\-]+)/i, 1]
      clean_payee(raw)
    end

    def clean_payee(text)
      return if text.blank?

      cleaned = text.gsub(/[-_]/, " ").gsub(/[^A-Za-zÀ-ÿ ]/, " ").squish
      return if cleaned.blank?

      cleaned.titleize if cleaned.match?(/[A-Za-zÀ-ÿ]{3,}/)
    end

    def usable_payee?(name, payer)
      return false if name.blank?
      return false if skip_payee_line?(name)
      return false if payer.present? && name.downcase.include?(payer.downcase.split.first.to_s)

      true
    end

    def skip_payee_line?(name)
      name.match?(/\b(Recibo|Recebi|Portador|Referente|Quantia|Valor|Data|Cpf|Cnpj|Rg|Porto Alegre)\b/i)
    end
  end
end
