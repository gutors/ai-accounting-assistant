require "chunky_png"
require "pure_jpeg"
require "qrio"
require "tempfile"

module PhotoSymbols
  Symbols = Data.define(:chave, :qr_url)

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

    def set(filename, chave: nil, qr_url: nil)
      @results[filename] = Symbols.new(chave:, qr_url:)
    end

    def scan(bytes:, filename:, text: nil)
      @results.fetch(filename) { Symbols.new(chave: nil, qr_url: nil) }
    end
  end

  class Real
    def scan(bytes:, filename: nil, text: nil)
      qr_url = nil
      qr_chave = nil
      code_chave = nil

      PhotoZbar.scan(bytes).each do |kind, payload|
        if kind.match?(/qr/i)
          qr_url = payload if payload.start_with?("http")
          qr_chave ||= chave_from_qr(payload)
        elsif kind.match?(/code-?128/i)
          code_chave ||= forty_four(payload)
        end
      end
      return Symbols.new(chave: qr_chave || code_chave, qr_url:) if qr_chave || code_chave || qr_url

      image = load_image(bytes)
      payload = qr_payload(image) if image
      if payload
        qr_url = payload if payload.start_with?("http")
        qr_chave = chave_from_qr(payload)
      end
      code_chave = forty_four(code128_payload(image)) if image && qr_chave.nil?
      printed_chave = forty_four(PhotoOcr.resolve(bytes, text)) unless qr_chave || code_chave
      Symbols.new(chave: qr_chave || code_chave || printed_chave, qr_url:)
    rescue ChunkyPNG::Exception, ArgumentError
      Symbols.new(chave: nil, qr_url: nil)
    end

    private

    def load_image(bytes)
      return if bytes.blank?

      if png?(bytes)
        ChunkyPNG::Image.from_blob(bytes)
      elsif jpeg?(bytes)
        jpeg = PureJPEG.read(bytes)
        return unless jpeg

        image = ChunkyPNG::Image.new(jpeg.width, jpeg.height)
        jpeg.height.times do |y|
          jpeg.width.times do |x|
            pixel = jpeg[x, y]
            image[x, y] = ChunkyPNG::Color.rgb(pixel.r, pixel.g, pixel.b)
          end
        end
        image
      end
    rescue PureJPEG::DecodeError
      nil
    end

    def png?(bytes)
      bytes.byteslice(0, 8) == "\x89PNG\r\n\x1A\n".b
    end

    def jpeg?(bytes)
      bytes.byteslice(0, 2) == "\xFF\xD8".b
    end

    def qr_payload(image)
      Tempfile.create([ "photo-symbols", ".png" ]) do |file|
        file.binmode
        file.write(image.to_blob)
        file.flush
        matrix = Qrio::Qr.load(file.path).qr
        modules = Array.new(matrix.height.to_i) { |y| Array.new(matrix.width.to_i) { |x| matrix[x, y] } }
        QrPayload.decode(modules)
      end
    rescue StandardError
      nil
    end

    def code128_payload(image)
      ys = [ image.height / 2 ]
      1.upto(9) { |i| ys << (image.height * i / 10) }
      ys.uniq.each do |y|
        payload = decode_code128_row(image, y)
        return payload if payload
      end
      nil
    end

    def decode_code128_row(image, y)
      row = image.width.times.map { |x| ChunkyPNG::Color.r(image[x, y]) < 128 ? 1 : 0 }
      runs = []
      row.each do |bit|
        if runs.empty? || runs.last[0] != bit
          runs << [ bit, 1 ]
        else
          runs.last[1] += 1
        end
      end
      min = runs.map(&:last).min
      return if min.nil? || min.zero?

      bits = runs.map { |bit, n| bit.to_s * (n.to_f / min).round }.join
      Code128.decode(bits)
    end

    def chave_from_qr(payload)
      forty_four(payload) || forty_four(URI.parse(payload).query)
    rescue URI::InvalidURIError, ArgumentError
      forty_four(payload)
    end

    def forty_four(value)
      NfeAccessKey.digits(value.to_s)
    end
  end
end
