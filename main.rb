# frozen_string_literal: true

require "gtk3"
require_relative "explorer"

Gtk.init

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

$css_provider = Gtk::CssProvider.new
$css_provider.load(path: "./assets/style/main.css")

$clipboard = Gtk::Clipboard.get(Gdk::Atom.intern("CLIPBOARD", false))

def update_app(ex, container, search_bar)
  # This function updates the displayed content of the explorer (the list of files/ folders)
  # it also updates the search bar content and window title

  # Remove the file list
  container.children.each { | child | container.remove(child) }

  # The scrollable window that will contain the list of files
  scroll_view = Gtk::ScrolledWindow.new
  scroll_view.set_size_request(APP_DEFAULT_WIDTH, APP_DEFAULT_HEIGHT)
  scroll_view.set_policy(Gtk::PolicyType::AUTOMATIC, Gtk::PolicyType::AUTOMATIC)

  file_box = Gtk::Box.new(:vertical)
  # Generate the header of the table
  grid = Gtk::Grid.new
  grid.set_column_homogeneous(true)

  %w[Filename Size Created].each_with_index do |name, index|
    label = Gtk::Label.new(name)
    label.style_context.add_provider($css_provider, Gtk::StyleProvider::PRIORITY_USER)
    label.style_context.add_class("title")
    grid.attach(label, index, 0, 1, 1)
  end
  container.add(grid)

  # Listing the files/ directories
  max_allowed_len = 20
  ex.listdir.each do |entry|
    # Crop the longest names
    if entry[:filename].length > max_allowed_len
      entry[:filename] = "#{entry[:filename][0..(max_allowed_len - 3)]}..."
    end

    name_field = Gtk::Label.new("\t#{entry[:filename]}").set_xalign(0.0)
    name_field.style_context.add_provider($css_provider, Gtk::StyleProvider::PRIORITY_USER)

    if entry[:type] == "file"
      name_field.set_text("\t📄 #{entry[:filename]}")
      name_field.style_context.add_class("file")
    end

    # Make the label clickable if it's a directory
    if entry[:type] == "directory"
      name_field = Gtk::EventBox.new  # A box is needed to handle the event. The label is placed inside.

      name_label = Gtk::Label.new("\t#{entry[:filename]}").set_xalign(0.0)
      name_label.style_context.add_provider($css_provider, Gtk::StyleProvider::PRIORITY_USER)
      name_label.set_text("\t📁 #{entry[:filename]}")
      name_label.style_context.add_class("directory")

      name_field.add_events([Gdk::EventMask::BUTTON_PRESS_MASK])

      name_field.signal_connect "button-press-event" do |_, event|
        if event.event_type == Gdk::EventType::DOUBLE_BUTTON_PRESS  # If the folder is double-clicked, explore it
          if entry[:filename] == "."  # Special case: Stay in the current directory
          elsif entry[:filename] == ".."  #Special case: Go to the previous directory in the path
            upper_dir = ex.current_path.split("/")
            if upper_dir.length > 1
              upper_dir = upper_dir[0..(upper_dir.length - 2)].join("/")
              ex.chdir(next_path: upper_dir)
            end
          else  # Move to the clicked directory normally
            ex.chdir(next_path: "#{ex.current_path}/#{entry[:filename]}")
          end

          update_app(ex, container, search_bar)
        end
      end
      name_field.add(name_label)
    end

    if entry[:type] == "link"
      name_field.set_text("\t🔗 #{entry[:filename]}")
      name_field.style_context.add_class("link")
    end

    grid = Gtk::Grid.new
    grid.set_column_homogeneous(true)
    grid.attach(name_field, 0, 0, 1, 1)
    grid.attach(Gtk::Label.new("\t#{entry[:size]}").set_xalign(0.0), 1, 0, 1, 1)
    grid.attach(Gtk::Label.new("\t#{entry[:date]}"), 2, 0, 1, 1)
    file_box.add(grid)
  end

  scroll_view.add(file_box)
  container.pack_start(scroll_view, expand: true, fill: true, padding: 0)
  container.show_all

  $window.title = "#{APP_NAME} - #{ex.current_path}"
  search_bar.text = ex.current_path
end

app_box = Gtk::Box.new(:vertical)
main_box = Gtk::Box.new(:vertical, 5)  # File/ directory list container

# The search bar
search_bar = Gtk::Box.new(:horizontal, 0)

current_path_entry = Gtk::Entry.new.set_text(explorer.current_path)
current_path_entry.signal_connect "key-press-event" do |_, event|
  if event.keyval == Gdk::Keyval::KEY_Return
    explorer.chdir(next_path: current_path_entry.text)  # Set the new path
    update_app(explorer, main_box, current_path_entry)  # Update the displayed elements to match the current directory
  end
end

previous_btn = Gtk::Button.new(label: "⬅️")
copy_btn = Gtk::Button.new(label: "📋")

# Apply the style to the previous buttons
[previous_btn, copy_btn].each do |btn|
  btn.style_context.add_provider($css_provider, Gtk::StyleProvider::PRIORITY_USER)
end

previous_btn.signal_connect "button-press-event" do
  upper_dir = explorer.current_path.split("/")
  if upper_dir.length > 1
    upper_dir = upper_dir[0..(upper_dir.length - 2)].join("/")
    explorer.chdir(next_path: upper_dir)
    update_app(explorer, main_box, current_path_entry)
  end
end

copy_btn.signal_connect "button-press-event" do
  $clipboard.set_text(explorer.current_path)
end

search_bar.pack_start(current_path_entry, expand: true, fill: true, padding: 0)
search_bar.pack_start(previous_btn, expand: false, fill: false, padding: 0)
search_bar.pack_start(copy_btn, expand: false, fill: false, padding: 0)
search_bar.show_all

app_box.pack_start(search_bar, expand: false, fill: false, padding: 0)  # Packing the search bar
app_box.pack_start(main_box, expand: true, fill: true, padding: 0)  # Packing the file list container

# The bottom menu bar
menubar = Gtk::MenuBar.new
menubar.style_context.add_provider($css_provider, Gtk::StyleProvider::PRIORITY_USER)
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

# Previous/ Next visited path menu
menubar_item_history_p = Gtk::MenuItem.new(label: "<-")
menubar_item_history_n = Gtk::MenuItem.new(label: "->")

menubar_item_history_p.signal_connect "activate" do
  if explorer.history.length > 0
    explorer.chdir(next_path: explorer.history[explorer.history_pos-1], ignore_history: true)
    update_app(explorer, main_box, current_path_entry)
  end
end

menubar_item_history_n.signal_connect "activate" do
  # FIXME
  unless explorer.history[explorer.history_pos+1].nil?
    explorer.chdir(next_path: explorer.history[explorer.history_pos+1], ignore_history: true)
    update_app(explorer, main_box, current_path_entry)
  end
end
# End of the Previous/ Next visited path menu

menubar.append(menubar_item_settings)
# menubar.append(menubar_item_history_p)
# menubar.append(menubar_item_history_n)

update_app(explorer, main_box, current_path_entry)  # The initial displaying of files

$window.add(app_box)

$window.show_all
Gtk.main