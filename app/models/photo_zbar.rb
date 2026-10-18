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
      ext = PhotoImage.extension(bytes)
      return [] if ext.nil? || bytes.blank?

      Tempfile.create([ "photo-zbar", ext ]) do |file|
        file.binmode
        file.write(bytes)
        file.flush
        out, _err, status = Open3.capture3(binary, "-q", file.path)
        return [] unless status.success? || status.exitstatus == 4

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
  end
end
