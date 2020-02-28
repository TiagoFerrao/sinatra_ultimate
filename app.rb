# frozen_string_literal: true

require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'pry-byebug'
require 'better_errors'
require_relative 'cookbook'
require_relative 'recipe'
require_relative 'parsing'

csv_file   = File.join(__dir__, 'recipes.csv')
cookbook   = Cookbook.new(csv_file)

# set :bind, '0.0.0.0' -> if you want to demo with ngrok for example

# configure :development do
#   use BetterErrors::Middleware
#   BetterErrors.application_root = File.expand_path(__dir__)
# end

get '/' do
  @recipes = cookbook.all
  erb :recipes
end

get '/new' do
  erb :new_recipe
end

post '/new' do
  new_recipe = Recipe.new(params['name'], params['description'], params['prep_time'])
  cookbook.add_recipe(new_recipe)
  redirect '/'
end
