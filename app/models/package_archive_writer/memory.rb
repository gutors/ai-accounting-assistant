module PackageArchiveWriter
  class Memory
    def initialize
      @mutex = Mutex.new
      @folders = {}
      @calls = []
    end

    def calls
      @mutex.synchronize { @calls.dup }
    end

    def folders
      @mutex.synchronize { @folders.dup }
    end

    def latest_files
      @mutex.synchronize { @calls.last&.fetch(:files, nil) }
    end

    def plant(id:, parent_id:, name:, files: {})
      @mutex.synchronize do
        @folders[id] = { parent_id: parent_id, name: name, files: files.dup }
      end
    end

    def replace_month_folder(parent_id:, name:, folder_id:, files:)
      @mutex.synchronize do
        @calls << { parent_id: parent_id, name: name, folder_id: folder_id, files: files }
        apply_replace(parent_id: parent_id, name: name, folder_id: folder_id, files: files)
      end
    end

    private

    def apply_replace(parent_id:, name:, folder_id:, files:)
      if folder_id.present?
        @folders[folder_id] = { parent_id: parent_id, name: name, files: files.dup }
        return folder_id
      end

      matches = @folders.select { |_id, folder| folder[:parent_id] == parent_id && folder[:name] == name }
      if matches.size > 1
        raise AmbiguousFolder, "more than one folder named #{name}"
      elsif matches.size == 1
        id = matches.keys.first
        @folders[id] = { parent_id: parent_id, name: name, files: files.dup }
        id
      else
        id = "folder-#{@folders.size + 1}"
        @folders[id] = { parent_id: parent_id, name: name, files: files.dup }
        id
      end
    end
  end
end
