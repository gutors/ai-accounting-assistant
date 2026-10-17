require "open3"
require "tmpdir"

module PhotoPdf
  class << self
    attr_writer :binary

    def binary
      @binary || "pdftoppm"
    end

    def reset!
      @binary = nil
    end

    def pdf?(bytes)
      bytes.to_s.byteslice(0, 4) == "%PDF"
    end

    def png_pages(bytes)
      return unless pdf?(bytes)
      return [] if bytes.blank?

      Dir.mktmpdir("photo-pdf-") do |dir|
        input = File.join(dir, "input.pdf")
        prefix = File.join(dir, "page")
        File.binwrite(input, bytes)
        _out, _err, status = Open3.capture3(binary, "-png", "-r", "150", input, prefix)
        return [] unless status.success?

        Dir.glob(File.join(dir, "page-*.png")).sort_by { |path|
          path[/-(\d+)\.png\z/, 1].to_i
        }.map { |path| File.binread(path) }
      end
    rescue Errno::ENOENT, Errno::EACCES
      []
    end
  end
end
