require 'csv'
require_relative 'recipe'

class Cookbook
  def initialize(csv_file_path)
    @recipes = []
    @csv_file = csv_file_path
    # create @recipes
    CSV.foreach(csv_file_path) do |row|
      @recipes << Recipe.new(row[0], row[1], row[2], row[3] == "true" )
    end
  end

  def all
    @recipes
  end

  def mark_recipe(index)
    @recipes[index].done = true
    save
  end

  def add_recipe(recipe)
    @recipes << recipe
    save
  end

  def remove_recipe(recipe_index)
    @recipes.delete_at(recipe_index)
    save
  end

  def save
    CSV.open(@csv_file, 'wb') do |csv|
      @recipes.each do |recipe|
        csv << [recipe.name, recipe.description, recipe.prep_time, recipe.done]
      end
    end
  end
end
