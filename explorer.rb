# frozen_string_literal: true

class Explorer
  attr_reader :current_path

  def initialize(path:)
    @current_path = path
    @history = []
  end

  def listdir(show_hidden: false)
    entries = []
    Dir.entries(@current_path).sort!.each do |entry|
      entries << {
        :filename => entry,
        :size => File.size(entry),  # file size in byte
        :type => File.ftype(entry)
      }
    end

    # Remove the file that starts with a dot
    unless show_hidden
      entries.filter! {|entry| !entry[:filename].start_with?(".")}
    end

    entries
  end

  def chdir(next_path:)
    @current_path = next_path if File.exist?(next_path)
  end
end
