# frozen_string_literal: true

class Explorer
  attr_reader :current_path
  attr_reader :history
  attr_reader :configuration
  attr_writer :configuration

  def initialize(path:)
    @current_path = path
    @history = []
    @configuration = {
      :show_hidden => false,  # Toggle the display of hidden files (starting with a dot)
      :keep_history => true,  # Toggle memorization of the last viewed folders
      :history_retention => 10,  # Number of previous visited folder that should be kept
      :format_filesize => true,  # More human-readable file size (i.e. 4096 bytes -> 4 kilobytes)
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

        size = File.size(full_file_path)
        if @configuration[:format_filesize]
          size = format_size(size)
        else
          size = "#{size} o"
        end

        entries << {
          :filename => entry,
          :size => size,  # file size in byte
          :type => File.ftype(full_file_path)  # directory of file (mainly)
        }
      end
    end

    entries
  end

  def chdir(next_path:)
    if File.exist?(next_path)
      if @configuration[:keep_history]
        @history << @current_path  # Store the last path
        if @history.length > @configuration[:history_retention]
          @history = @history[1..]
        end
      end

      @current_path = next_path
      @current_path = next_path[0..-2] if @current_path.end_with?("/")  # Trim the trailing slash if there is one
    end
  end

  def format_size(number)
    units = ["", "K", "M", "G", "T"]
    i = 0
    number = number.to_f
    while (number >= 1024) && (i < units.length - 1)
      i += 1
      number = number / 1024
    end
    "#{'%.1f' % number} #{units[i]}o"
  end
end
