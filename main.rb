# frozen_string_literal: true

require_relative 'explorer'


PACKAGE_NAME = "fr.gabhas.explorer"

APP_NAME = "File Explorer"
APP_WIDTH = 720
APP_HEIGHT = 480
APP_START_DIR = Dir.pwd

ICON_DIR = "#{APP_START_DIR}/assets/icons"
ICON_BASE_NAME = "folder-icon"
ICON_SIZES = [16, 32, 64, 128]

# icons = []
# ICON_SIZES.each do |size|
#   icons << GdkPixbuf::Pixbuf.new(file: "#{ICON_DIR}/folder-icon-#{size}.png")
# end

explorer = Explorer.new(path: APP_START_DIR)

puts explorer.current_path
puts explorer.listdir(show_hidden: true)
