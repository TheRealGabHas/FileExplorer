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

$window = Gtk::Window.new(:toplevel)
$window.title = APP_NAME

# Application size
$window.set_size_request(APP_MIN_WIDTH, APP_MIN_HEIGHT)
$window.set_default_size(APP_DEFAULT_WIDTH, APP_DEFAULT_HEIGHT)

$window.set_icon_list(icons)
$window.signal_connect("destroy") { Gtk.main_quit }

def update_app(ex, container, search_bar)
  # Remove the file list
  container.children.each { | child | container.remove(child) }

  # The scrollable window that will contain the list of files
  scroll_view = Gtk::ScrolledWindow.new
  scroll_view.set_size_request(APP_DEFAULT_WIDTH, APP_DEFAULT_HEIGHT)
  scroll_view.set_policy(Gtk::PolicyType::AUTOMATIC, Gtk::PolicyType::AUTOMATIC)

  file_box = Gtk::Box.new(:vertical)
  # Header of the table
  grid = Gtk::Grid.new
  grid.set_column_homogeneous(true)
  grid.attach(Gtk::Label.new("Filename"), 0, 0, 1, 1)
  grid.attach(Gtk::Label.new("Size"), 1, 0, 1, 1)
  grid.attach(Gtk::Label.new("Created"), 2, 0, 1, 1)
  container.add(grid)

  # Listing the files/ directories
  max_allowed_len = 20
  ex.listdir.each do |entry|
    # Crop the longest names
    if entry[:filename].length > max_allowed_len
      entry[:filename] = "#{entry[:filename][0..(max_allowed_len - 3)]}..."
    end

    name_field = Gtk::Label.new("\t#{entry[:filename]}")
    # Add a button to explore the folder if the entry is a directory
    if entry[:type] == "directory"
      name_field.set_text("\t#{entry[:filename]} ▶️")
      name_field.set_has_window(true)
      name_field.add_events([Gdk::EventMask::BUTTON_PRESS_MASK])

      name_field.signal_connect "button-press-event" do
        ex.chdir(next_path: "#{ex.current_path}/#{entry[:filename]}")
        update_app(ex, container, search_bar)
        search_bar.text = ex.current_path
      end
    end

    grid = Gtk::Grid.new
    grid.set_column_homogeneous(true)
    grid.attach(name_field.set_xalign(0.0), 0, 0, 1, 1)
    grid.attach(Gtk::Label.new("\t#{entry[:size]}").set_xalign(0.0), 1, 0, 1, 1)
    grid.attach(Gtk::Label.new("\t#{entry[:date]}"), 2, 0, 1, 1)
    file_box.add(grid)
  end

  scroll_view.add(file_box)
  container.pack_start(scroll_view, expand: true, fill: true, padding: 0)
  container.show_all

  $window.title = "#{APP_NAME} - #{ex.current_path}"
end

app_box = Gtk::Box.new(:vertical)
main_box = Gtk::Box.new(:vertical, 5)  # File/ directory list container

# The search bar
current_path_entry = Gtk::Entry.new.set_text(explorer.current_path)
current_path_entry.signal_connect "key-press-event" do |widget, event|
  if event.keyval == Gdk::Keyval::KEY_Return
    explorer.chdir(next_path: current_path_entry.text)  # Set the new path
    update_app(explorer, main_box, current_path_entry)  # Update the displayed elements to match the current directory
  end
end

app_box.pack_start(current_path_entry, expand: false, fill: false, padding: 0)  # Packing the search bar
app_box.pack_start(main_box, expand: true, fill: true, padding: 0)  # Packing the file list container

# The bottom menu bar
menubar = Gtk::MenuBar.new
app_box.pack_start(menubar, expand: false, fill: false, padding: 0)

menubar_item_settings = Gtk::MenuItem.new(label: "Settings")

# The settings menu and submenu
settings_submenu = Gtk::Menu.new
toggle_hidden_files = Gtk::CheckMenuItem.new(label: "Show hidden files")
toggle_hidden_files.signal_connect "activate" do
  explorer.configuration[:show_hidden] = !explorer.configuration[:show_hidden]  # Invert the current setting
  update_app(explorer, main_box, current_path_entry)
end

toggle_history_view = Gtk::CheckMenuItem.new(label: "History")
toggle_history_view.set_active(true)  # This setting is enabled by default
toggle_history_view.signal_connect "activate" do
  explorer.configuration[:keep_history] = !explorer.configuration[:keep_history]
end

toggle_filesize_formating = Gtk::CheckMenuItem.new(label: "Format filesize")
toggle_filesize_formating.set_active(true)  # This setting is enabled by default
toggle_filesize_formating.signal_connect "activate" do
  explorer.configuration[:format_filesize] = !explorer.configuration[:format_filesize]
  update_app(explorer, main_box, current_path_entry)
end

toggle_size_estimation = Gtk::CheckMenuItem.new(label: "Compute folder size")
toggle_size_estimation.set_active(false)  # This setting is disabled by default
toggle_size_estimation.signal_connect "activate" do
  explorer.configuration[:estimate_folder_size] = !explorer.configuration[:estimate_folder_size]
  update_app(explorer, main_box, current_path_entry)
end

settings_submenu.append(toggle_hidden_files)
settings_submenu.append(toggle_history_view)
settings_submenu.append(toggle_filesize_formating)
settings_submenu.append(toggle_size_estimation)
menubar_item_settings.set_submenu(settings_submenu)
# End of the settings menu and submenu

menubar.append(menubar_item_settings)

update_app(explorer, main_box, current_path_entry)  # The initial displaying of files

$window.add(app_box)

$window.show_all
Gtk.main