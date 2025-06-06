# frozen_string_literal: true

require 'gtk3'

PACKAGE_NAME = "fr.gabhas.explorer"
APP_NAME = "File Explorer"
APP_WIDTH = 720
APP_HEIGHT = 480


app = Gtk::Application.new(PACKAGE_NAME, :flags_none)

app.signal_connect "activate" do |application|
  window = Gtk::ApplicationWindow.new(application)
  window.set_title(APP_NAME)
  window.set_default_size(APP_WIDTH, APP_HEIGHT)

  vbox = Gtk::Box.new(:vertical, 5) # 5 pixels spacing between children
  window.add(vbox)

  current_folder_field = Gtk::Entry.new
  vbox.add(current_folder_field)

  window.show_all
end

puts app.run
