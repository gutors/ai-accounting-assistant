require "open3"
require "tempfile"

module PhotoZbar
  class << self
    attr_writer :binary

    def binary
      @binary || "zbarimg"
    end

    def reset!
      @binary = nil
    end

    def scan(bytes)
      ext = extension(bytes)
      return [] if ext.nil? || bytes.blank?

      Tempfile.create([ "photo-zbar", ext ]) do |file|
        file.binmode
        file.write(bytes)
        file.flush
        out, _err, status = Open3.capture3(binary, "-q", file.path)
        return [] unless status.success? || status.exitstatus == 1

        parse(out)
      end
    rescue Errno::ENOENT, Errno::EACCES
      []
    end

    private

    def parse(out)
      out.to_s.each_line.filter_map { |line|
        kind, payload = line.strip.split(":", 2)
        next if kind.blank? || payload.blank?

        [ kind, payload ]
      }
    end

    def extension(bytes)
      if bytes.byteslice(0, 8) == "\x89PNG\r\n\x1A\n".b
        ".png"
      elsif bytes.byteslice(0, 2) == "\xFF\xD8".b
        ".jpg"
      end
    end
  end
end
