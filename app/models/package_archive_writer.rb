module PackageArchiveWriter
  SCOPE = "https://www.googleapis.com/auth/drive"

  class Error < StandardError; end
  class AmbiguousFolder < Error; end

  class << self
    def current
      @current ||= build
    end

    def current=(writer)
      @current = writer
    end

    def reset!
      @current = Memory.new
    end

    def build
      if ENV["GOOGLE_DRIVE_REFRESH_TOKEN"].present?
        Drive.new
      else
        Memory.new
      end
    end
  end
end
