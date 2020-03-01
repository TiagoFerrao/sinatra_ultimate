## Synopsis

A simple to do program, complete with due dates, categories, undelete, etc.
Currently doesn't support multiple users (so you might use it locally in your
own browser). Written in Ruby/Sinatra. The code is installed at http://simple-to-do.herokuapp.com.

## Installation

Simply download into any directory you like, make sure you have Ruby and the
Ruby gem 'bundler' installed, then run `bundle install`. Then run `ruby todo.rb`
and go to http://localhost:4567 on your local machine.

## Tests

Make sure the Ruby gem `rake` is installed, then run `rake test` in the main
directory (the place where `todo.rb` is) to run all tests. Coverage includes all
`get` methods and helper methods that don't simply write to the YAML store.
I still don't know how to test my `put` methods. Help?

## Plans

I intend to add user account support. Other features I want to add include
pagination and search. Feel free to add feature requests on
http://simple-to-do.herokuapp.com, although anybody will be able to delete your
suggestions...

I need help writing tests of the `post` logic. I just have to write a bunch of
unit tests (and refactor generally).

## Contributors

Just Larry Sanger (yo.larrysanger@gmail.com) at this point.
