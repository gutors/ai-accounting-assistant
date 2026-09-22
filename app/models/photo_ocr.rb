require "open3"
require "tempfile"

module PhotoOcr
  class << self
    attr_writer :binary

    def binary
      @binary || "tesseract"
    end

    def reset!
      @binary = nil
    end

    def text(bytes)
      ext = extension(bytes)
      return "" if ext.nil? || bytes.blank?

      Tempfile.create([ "photo-ocr", ext ]) do |file|
        file.binmode
        file.write(bytes)
        file.flush
        out, _err, status = Open3.capture3(binary, file.path, "stdout", "-l", "por+eng", "--psm", "6")
        return "" unless status.success?

        out.to_s
      end
    rescue Errno::ENOENT, Errno::EACCES
      ""
    end

    private

    def extension(bytes)
      if bytes.byteslice(0, 8) == "\x89PNG\r\n\x1A\n".b
        ".png"
      elsif bytes.byteslice(0, 2) == "\xFF\xD8".b
        ".jpg"
      end
    end
  end
end
