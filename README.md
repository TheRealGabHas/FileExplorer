# File Explorer

This application is a simple file explorer made in Ruby. It relies on GTK3 for the graphical interface.

The goal of this project is to learn Ruby.


## Requirements

The project is built with Ruby:
- [Ruby 3.3.8](https://www.ruby-lang.org/en/downloads/)
- [GTK-3](https://docs.gtk.org/gtk3/)


## How to run this project ?

The first step is to install Ruby : see the [official website](https://www.ruby-lang.org/en/downloads/).

Then use the `gem` command to install GTK 3:
```shell
gem install gtk3
```

Finally, the application can be executed with the following command:
```shell
ruby main.rb
```


## Project structure

- [`main.rb`](main.rb): Entrypoint for the application. Contains the code description of the UI
- [`explorer.rb`](explorer.rb): The file explorer class and methods
- [`Gemfile`](Gemfile): The file that contains the project dependencies
- [`config.yml`](config.yml): Configuration option for the file explorer
- [`README.md`](README.md): The current file you are reading, detailing the project
- [`assets`](assets): A folder containing the project resources (i.e. icon, font...) 


## Credits

Icons:
- [Folder](assets/icons/folder-icon-128.png) is from [Freepik](https://www.flaticon.com/authors/freepik)