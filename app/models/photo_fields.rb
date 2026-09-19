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
      Miss.new
    end
  end
end
