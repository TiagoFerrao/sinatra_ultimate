require 'nokogiri'
require 'open-uri'
require_relative 'recipe'
require 'pry-byebug'

class Parsing

  def initialize(ingredient)
    path = "https://www.bbcgoodfood.com/search/recipes?query=#{ingredient})"
    @doc = Nokogiri::HTML(open(path),nil, 'utf-8')
  end

  def get_results
    recipe_node = '.node.node-recipe.node-teaser-item'
    name_class = '.teaser-item__title a'
    description_class = '.field-item'
    prep_time = '.teaser-item__info-items li.teaser-item__info-item--total-time'


    @doc.css(recipe_node).map do |node|
      name = node.at_css(name_class).text.strip
      description = node.at_css(description_class).text.strip
      time = node.at_css(prep_time).text.strip
      Recipe.new(name, description, time)
    end
  end
end
