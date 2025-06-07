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
    }
  end

  def listdir
    entries = []
    Dir.entries(@current_path).sort!.each do |entry|
      full_file_path = "#{@current_path}/#{entry}"
      if File.exist?(full_file_path)
        entries << {
          :filename => entry,
          :size => File.size(full_file_path),  # file size in byte
          :type => File.ftype(full_file_path)  # directory of file (mainly)
        }
      end
    end

    # Remove the file that starts with a dot
    unless @configuration[:show_hidden]
      entries.filter! {|entry| !entry[:filename].start_with?(".")}
    end

    entries
  end

  def chdir(next_path:)
    if File.exist?(next_path)
      @history << @current_path  # Store the last path
      @current_path = next_path
      @current_path = next_path[0..-2] if @current_path.end_with?("/")  # Trim the trailing slash if there is one
    end
  end
end
