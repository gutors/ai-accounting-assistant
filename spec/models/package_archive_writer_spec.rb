require "rails_helper"
require "ostruct"

RSpec.describe PackageArchiveWriter, type: :model do
  class FakeFileList
    attr_reader :files, :next_page_token

    def initialize(files)
      @files = files
      @next_page_token = nil
    end
  end

  class FakeDriveService
    attr_reader :created, :deleted

    def initialize(named_folders: [])
      @named_folders = named_folders
      @created = []
      @deleted = []
      @seq = 0
    end

    def list_files(q:, fields: nil, page_token: nil)
      if q.include?("name = '2026-05'") && q.include?("application/vnd.google-apps.folder")
        FakeFileList.new(@named_folders)
      else
        FakeFileList.new([])
      end
    end

    def create_file(metadata, upload_source: nil, content_type: nil, fields: nil)
      @seq += 1
      id = "created-#{@seq}"
      @created << {
        id: id,
        name: metadata.name,
        mime_type: metadata.mime_type,
        parents: metadata.parents,
        content_type: content_type,
        bytes: upload_source&.read
      }
      OpenStruct.new(id: id)
    end

    def delete_file(id)
      @deleted << id
    end
  end

  it "replace_month_folder raises when two folders share the name" do
    folders = [ OpenStruct.new(id: "a"), OpenStruct.new(id: "b") ]
    drive = PackageArchiveWriter::Drive.new(service: FakeDriveService.new(named_folders: folders))

    expect do
      drive.replace_month_folder(parent_id: "parent", name: "2026-05", folder_id: nil, files: {})
    end.to raise_error(PackageArchiveWriter::AmbiguousFolder)
  end

  it "test adapter stores month folder in memory" do
    memory = PackageArchiveWriter::Memory.new
    id = memory.replace_month_folder(
      parent_id: CloseHelpers::ARCHIVE_FOLDER_ID,
      name: "2026-05",
      folder_id: nil,
      files: { "resumo-2026-05.xlsx" => "bytes" }
    )

    expect(memory.folders[id][:name]).to eq("2026-05")
    expect(memory.folders[id][:files]).to include("resumo-2026-05.xlsx" => "bytes")
    expect(memory).not_to be_a(PackageArchiveWriter::Drive)
  end

  it "token present selects Drive API v3 adapter" do
    with_env(
      "GOOGLE_DRIVE_REFRESH_TOKEN" => "refresh-token",
      "GOOGLE_CLIENT_ID" => "client-id",
      "GOOGLE_CLIENT_SECRET" => "client-secret"
    ) do
      expect(PackageArchiveWriter.build).to be_a(PackageArchiveWriter::Drive)
    end
  end
end
