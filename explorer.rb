# frozen_string_literal: true

class Explorer
  attr_reader :current_path
  attr_reader :history
  attr_accessor :history_pos
  attr_accessor :configuration

  def initialize(path:)
    @current_path = path
    @history = [@current_path]
    @history_pos = 0
    @configuration = {
      :show_hidden => false,  # Toggle the display of hidden files (starting with a dot)
      :keep_history => true,  # Toggle memorization of the last viewed folders
      :history_retention => 10,  # Number of previous visited folder that should be kept
      :format_filesize => true,  # More human-readable file size (i.e. 4096 bytes -> 4 kilobytes)
      :estimate_folder_size => false,  # Whether to compute the size of the content inside a directory. Current not optimized and causing poor performance on large directories
    }
  end

  def listdir
    entries = []
    Dir.entries(@current_path).sort!.each do |entry|
      # Ignore the file that starts with a dot if the settings is disabled
      if (@configuration[:show_hidden] == false) && entry.start_with?(".")
        next
      end

      full_file_path = "#{@current_path}/#{entry}"
      if File.exist?(full_file_path)
        ftype = File.ftype(full_file_path)
        begin

          # Compute the size of the content if the entry is a directory and the `estimate_folder_size` setting is enabled
          size = File.size(full_file_path)
          if ftype == "directory"
            if @configuration[:estimate_folder_size]
              size = compute_dir_size(path: full_file_path)
            end
          end

          # Format the size label
          @configuration[:format_filesize] ? size = format_size(size) : size = "#{size} o"

          entries << {
            :filename => entry,
            :size => size,  # file size in byte
            :type => ftype,  # directory of file (mainly)
            :date => File.ctime(full_file_path).ctime,  # creation date
          }

        rescue => _
          # Ignore unaccessible files
        end
      end
    end

    entries
  end

  def chdir(next_path:, ignore_history: false)
    # The `ignore_history` argument is set to true to avoid logging the visited path
    if File.exist?(next_path) && File.ftype(next_path) == "directory"
      if @configuration[:keep_history] && !ignore_history
        @history << @current_path  # Store the last path
        if @configuration[:history_retention] < @history.length
          @history = @history[1..]
        end
      end
      @history_pos += 1 if @history_pos < @history.length
      @current_path = next_path
      @current_path = next_path[0..-2] if @current_path.end_with?("/")  # Trim the trailing slash if there is one
    end
  end

  def format_size(number)
    return "#{number} o" if number < 1024
    units = ["", "K", "M", "G", "T"]
    i = 0
    number = number.to_f
    while (number >= 1024) && (i < units.length - 1)
      i += 1
      number = number / 1024
    end
    "#{'%.1f' % number} #{units[i]}o"
  end

  def compute_dir_size(path:, limit: 3)
    # Estimate the size of the content inside a folder
    # Also explore subfolders, up to 3 layers deep
    size = 0
    Dir.entries(path).each do |entry|
      next if %w[. ..].include?(entry)  # ignore those special files

      p = "#{path}/#{entry}"
      File.directory?(p) && limit > 0 ? size += compute_dir_size(path: p, limit: limit-1) : size += File.size(p)
    end
    size
  end
end
