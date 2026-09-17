require "google/apis/drive_v3"
require "googleauth"

module PackageArchiveWriter
  class Drive
    FOLDER_MIME = "application/vnd.google-apps.folder"
    MIME_BY_EXT = {
      "xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "csv" => "text/csv",
      "pdf" => "application/pdf",
      "jpg" => "image/jpeg",
      "jpeg" => "image/jpeg",
      "png" => "image/png",
      "webp" => "image/webp",
      "xml" => "application/xml"
    }.freeze

    def initialize(service: nil)
      @service = service
    end

    def replace_month_folder(parent_id:, name:, folder_id:, files:)
      id = folder_id.presence || resolve_folder_id(parent_id, name)
      replace_children(id, files)
      id
    rescue AmbiguousFolder
      raise
    rescue StandardError
      raise Error, "Drive write failed"
    end

    private

    def service
      @service ||= build_service
    end

    def build_service
      credentials = Google::Auth::UserRefreshCredentials.new(
        client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
        client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
        refresh_token: ENV.fetch("GOOGLE_DRIVE_REFRESH_TOKEN"),
        scope: [ SCOPE ]
      )
      Google::Apis::DriveV3::DriveService.new.tap do |drive|
        drive.authorization = credentials
      end
    end

    def resolve_folder_id(parent_id, name)
      found = list_named_folders(parent_id, name)
      if found.size > 1
        raise AmbiguousFolder, "more than one folder named #{name}"
      elsif found.size == 1
        found.first.id
      else
        create_folder(parent_id, name)
      end
    end

    def list_named_folders(parent_id, name)
      query = "name = '#{name}' and mimeType = '#{FOLDER_MIME}' and '#{parent_id}' in parents and trashed = false"
      list_all(query)
    end

    def replace_children(folder_id, files)
      list_all("'#{folder_id}' in parents and trashed = false").each do |child|
        service.delete_file(child.id)
      end

      dir_ids = { "" => folder_id }
      files.each do |path, bytes|
        parts = path.split("/")
        filename = parts.pop
        dir_key = ""
        parts.each do |dir|
          parent = dir_ids[dir_key]
          dir_key = dir_key.empty? ? dir : "#{dir_key}/#{dir}"
          dir_ids[dir_key] ||= create_folder(parent, dir)
        end
        upload_file(dir_ids[parts.join("/")], filename, bytes)
      end
    end

    def list_all(query)
      files = []
      page_token = nil
      loop do
        opts = { q: query, fields: "nextPageToken, files(id, name)" }
        opts[:page_token] = page_token if page_token.present?
        response = service.list_files(**opts)
        files.concat(Array(response.files))
        page_token = response.next_page_token
        break if page_token.blank?
      end
      files
    end

    def create_folder(parent_id, name)
      metadata = Google::Apis::DriveV3::File.new(
        name: name,
        mime_type: FOLDER_MIME,
        parents: [ parent_id ]
      )
      service.create_file(metadata, fields: "id").id
    end

    def upload_file(parent_id, filename, bytes)
      ext = File.extname(filename).delete(".").downcase
      metadata = Google::Apis::DriveV3::File.new(name: filename, parents: [ parent_id ])
      service.create_file(
        metadata,
        upload_source: StringIO.new(bytes),
        content_type: MIME_BY_EXT.fetch(ext, "application/octet-stream"),
        fields: "id"
      )
    end
  end
end
