# frozen_string_literal: true

require "gtk3"
require_relative "explorer"


PACKAGE_NAME = "fr.gabhas.explorer"

APP_NAME = "File Explorer"
APP_MIN_WIDTH = 120
APP_MIN_HEIGHT = 80
APP_DEFAULT_WIDTH = 720
APP_DEFAULT_HEIGHT = 480
APP_START_DIR = Dir.pwd

ICON_DIR = "#{APP_START_DIR}/assets/icons"
ICON_BASE_NAME = "folder-icon"
ICON_SIZES = [16, 32, 64, 128]

icons = []
ICON_SIZES.each { |size| icons << GdkPixbuf::Pixbuf.new(file: "#{ICON_DIR}/folder-icon-#{size}.png") }

explorer = Explorer.new(path: APP_START_DIR)

window = Gtk::Window.new(:toplevel)
window.title = APP_NAME

# Application size
window.set_size_request(APP_MIN_WIDTH, APP_MIN_HEIGHT)
window.set_default_size(APP_DEFAULT_WIDTH, APP_DEFAULT_HEIGHT)

window.set_icon_list(icons)
window.signal_connect("destroy") { Gtk.main_quit }

def update_file_list(ex, container)
  # Remove the file list
  container.children.each do |child|
    if child.is_a?(Gtk::Grid)  # Avoid removing the search bar
      container.remove(child)
    end
  end

  # Listing the files/ directories
  ex.listdir(show_hidden: true).each do |entry|
    grid = Gtk::Grid.new
    grid.set_column_homogeneous(true)
    grid.attach(Gtk::Label.new("\t#{entry[:filename]}").set_xalign(0.0), 0, 0, 1, 1)
    grid.attach(Gtk::Label.new("\t#{entry[:size]} o").set_xalign(0.0), 1, 0, 1, 1)
    grid.attach(Gtk::Label.new("\t#{entry[:type]}").set_xalign(0.0), 2, 0, 1, 1)
    container.add(grid)
  end
  container.show_all
end

main_box = Gtk::Box.new(:vertical, 5)

# The search bar
current_path_entry = Gtk::Entry.new.set_text(explorer.current_path)
current_path_entry.signal_connect("key-press-event") do |widget, event|
  if event.keyval == Gdk::Keyval::KEY_Return
    explorer.chdir(next_path: current_path_entry.text)
    update_file_list(explorer, main_box)
  end
end

main_box.add(current_path_entry)
update_file_list(explorer, main_box)

window.add(main_box)

window.show_all
Gtk.main