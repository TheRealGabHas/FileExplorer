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
    unless child.is_a?(Gtk::Entry)  # Avoid removing the search bar
      container.remove(child)
    end
  end

  # The scrollable window that will contain the list of files
  scroll_view = Gtk::ScrolledWindow.new
  scroll_view.set_size_request(APP_DEFAULT_WIDTH, APP_DEFAULT_HEIGHT)
  scroll_view.set_policy(Gtk::PolicyType::AUTOMATIC, Gtk::PolicyType::AUTOMATIC)

  file_box = Gtk::Box.new(:vertical)
  # Listing the files/ directories
  max_allowed_len = 40
  ex.listdir(show_hidden: true).each do |entry|
    # Crop the longest names
    if entry[:filename].length > max_allowed_len
      entry[:filename] = "#{entry[:filename][0..(max_allowed_len - 3)]}..."
    end

    grid = Gtk::Grid.new
    grid.set_column_homogeneous(true)
    grid.attach(Gtk::Label.new("\t#{entry[:filename]}").set_xalign(0.0), 0, 0, 1, 1)
    grid.attach(Gtk::Label.new("\t#{entry[:size]} o").set_xalign(0.0), 1, 0, 1, 1)
    grid.attach(Gtk::Label.new("\t#{entry[:type]}").set_xalign(0.0), 2, 0, 1, 1)
    file_box.pack_start(grid, expand: false, fill: false, padding: 2)
  end

  scroll_view.add(file_box)
  container.add(scroll_view)
  container.show_all
end

main_box = Gtk::Box.new(:vertical, 5)

# The search bar
current_path_entry = Gtk::Entry.new.set_text(explorer.current_path)
current_path_entry.signal_connect("key-press-event") do |widget, event|
  if event.keyval == Gdk::Keyval::KEY_Return
    explorer.chdir(next_path: current_path_entry.text)  # Set the new path
    update_file_list(explorer, main_box)  # Update the displayed elements to match the current directory
  end
end

main_box.pack_start(current_path_entry, expand: false, fill: false, padding: 5)
update_file_list(explorer, main_box)

window.add(main_box)

window.show_all
Gtk.main