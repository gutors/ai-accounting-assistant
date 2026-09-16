module DriveFolderUrl
  Result = Struct.new(:ok, :url, :folder_id, keyword_init: true) do
    def ok?
      ok
    end
  end

  HOST = "drive.google.com"
  FOLDERS_PATH = %r{\A/drive(?:/u/\d+)?/folders/([^/?]+)}

  module_function

  def parse(raw)
    stripped = raw.to_s.strip
    return Result.new(ok: true, url: nil, folder_id: nil) if stripped.blank?

    uri = URI.parse(stripped)
    unless uri.is_a?(URI::HTTPS) && uri.host == HOST
      return Result.new(ok: false)
    end

    match = uri.path.match(FOLDERS_PATH)
    return Result.new(ok: false) unless match

    Result.new(ok: true, url: stripped, folder_id: match[1])
  rescue URI::InvalidURIError
    Result.new(ok: false)
  end
end
