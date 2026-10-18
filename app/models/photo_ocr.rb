require "open3"
require "tempfile"

module PhotoOcr
  MARKERS = /EMITENTE|DESTINAT|VALOR|PAGAR|DOCUMENTO|CONSUMIDOR|NOTA|CHAVE|R\$|\d{2}\/\d{2}\/\d{2,4}|\d{20,}/i

  class << self
    attr_writer :binary

    def binary
      @binary || "tesseract"
    end

    def reset!
      @binary = nil
    end

    def resolve(bytes, supplied)
      return supplied.call if supplied.respond_to?(:call)
      return supplied unless supplied.nil?

      text(bytes)
    end

    def text(bytes)
      ext = PhotoImage.extension(bytes)
      return "" if ext.nil? || bytes.blank?

      Tempfile.create([ "photo-ocr", ext ]) do |file|
        file.binmode
        file.write(bytes)
        file.flush
        primary = run(file.path, "6")
        return primary if usable?(primary)

        fallback = run(file.path, "1")
        return fallback if usable?(fallback)

        primary.to_s
      end
    rescue Errno::ENOENT, Errno::EACCES
      ""
    end

    def header(bytes)
      image = PhotoImage.load(bytes)
      return "" unless image

      portraits = image.width > image.height ? [ image.rotate_right, image.rotate_left ] : [ image ]
      portraits.filter_map { |portrait| ocr_top(portrait) }.max_by { |text| header_score(text) }.to_s
    rescue Errno::ENOENT, Errno::EACCES, ChunkyPNG::Exception
      ""
    end

    private

    def run(path, psm)
      out, _err, status = Open3.capture3(binary, path, "stdout", "-l", "por+eng", "--psm", psm)
      out.to_s if status.success?
    end

    def usable?(text)
      text.to_s.match?(MARKERS)
    end

    def header_score(text)
      text.to_s.scan(/[A-Za-zÀ-ÿ]{4,}/).size
    end

    def ocr_top(image)
      height = [ image.height, [ 80, (image.height * 0.14).round ].max ].min
      crop = image.crop(0, 0, image.width, height)
      crop = crop.resample_bilinear(crop.width * 2, crop.height * 2) if crop.width < 900
      Tempfile.create([ "photo-ocr-header", ".png" ]) do |file|
        file.binmode
        file.write(crop.to_blob)
        file.flush
        run(file.path, "6")
      end
    end
  end
end
