require "chunky_png"
require "pure_jpeg"

module PhotoImage
  class << self
    def load(bytes)
      return if bytes.blank?

      case extension(bytes)
      when ".png"
        ChunkyPNG::Image.from_blob(bytes)
      when ".jpg"
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
    rescue ChunkyPNG::Exception, PureJPEG::DecodeError
      nil
    end

    def extension(bytes)
      return if bytes.blank?

      if bytes.byteslice(0, 8) == "\x89PNG\r\n\x1A\n".b
        ".png"
      elsif bytes.byteslice(0, 2) == "\xFF\xD8".b
        ".jpg"
      end
    end
  end
end
