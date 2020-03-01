require 'time'
require 'date'

class Task
  attr_accessor :id, :position, :description, :date_added, :date_due,
    :categories, :message, :ok, :overlong_description, :bad_categories

  def initialize(store, params)
    # assign an id only if there isn't one in params; if there is, this is an edit
    @id = (params[:id] ? params[:id].to_i : assign_id(store.ids))
    @ok = true # by default
    @message = ""
    @description = params["description"]
    unless check_description(@description) == "ok"
      # this outputs an error message for the user
      @message << " " + check_description(@description)
      @ok = false
      @overlong_description = @description # so this appears prefilled
      @bad_categories = params["categories"] # so this appears prefilled
    end
    @position = ""
    # add a new date_added only if one wasn't passed by the (hidden) edit field
    @date_added = (params[:date_added].nil? ? Time.new : Time.parse(params[:date_added]))
    unless params["date_due"] == ""
      @date_due = parse_date(params["date_due"])
      if @date_due == "error"
        @date_due = ""
        @message << " " + "Due date not saved. Please check the format."
        @bad_categories = params["categories"] # so this appears prefilled
        @overlong_description = params["description"] # so this appears prefilled
      end
    else
      @date_due = ""
    end
    @categories = {"completed" => false, "deleted" => false}
    if categories_validate(params["categories"]) == true
      @categories.merge!(categories_parse(params["categories"]))
    else
      @ok = false
      @bad_categories = params["categories"] # so this appears prefilled
      @overlong_description = params["description"] # so this appears prefilled
      @message << " " + categories_validate(params["categories"])
    end
  end

  # Determine highest ID; assign ID + 1 to this object
  def assign_id(all_ids)
    highest_id = all_ids.max || 10 # reserve first 10 ids for testing
    return highest_id + 1
  end

  # Description must be between 0 and 140 characters. Returns string.
  def check_description(description)
    # Return error message if description is blank.
    return "Description cannot be blank." if description == ""
    # Return error message if description is too long.
    if description.length > 140
      return "Description was #{description.length} characters long; cannot exceed 140."
    end
    # Otherwise "ok"
    return "ok"
  end

  def parse_date(user_input)
    begin
      parsed_date = ""
      now = Time.new
      case user_input
      when "now", "Now", "today", "Today"
        then parsed_date = now
      when "yesterday", "Yesterday"
        then parsed_date = Date.today - 1
      when "tomorrow", "Tomorrow"
        then parsed_date = Date.today + 1
      else
        parsed_date = Time.parse(user_input, now)
      end
      return parsed_date
    rescue
      return "error"
    end
  end

  # check that after comma separation, category contents are not too long &
  # contain no extraneous characters
  def categories_validate(categories)
    categories = categories.split(',')
    user_message = ""
    cats_seen = []
    categories.each do |cat|
      cat.strip!
      next if cats_seen.include?(cat)
      cats_seen << cat
      user_message << " Category '#{cat}' was too long." if cat.length > 25
      good_chars = [*'0'..'9', *'a'..'z', *'A'..'Z', '/', '-', '(', ')', '&',
        '#', '@', '+', '.', '?', '!'].join ' '
      word_chars = [*'0'..'9', *'a'..'z', *'A'..'Z'].join
      unless cat.split(//).all? {|char| good_chars.include?(char) }
        user_message << " Category '#{cat}' had weird characters."
      end
      unless cat.split(//).any? {|char| word_chars.include?(char)}
        user_message << " Category '#{cat}' lacks a letter or digit."
      end
    end
    return user_message unless user_message == ""
    return true
  end

  def categories_parse(categories)
    categories = categories.split(',')
    # remove leading and trailing whitespace & lowercase everything
    categories.map! { |cat| cat.strip.downcase }
    # remove blank category (when user types a comma with nothing after it)
    categories.reject! { |cat| cat == "" }
    # iterate through prepared array and save to @categories
    this_task_categories = {}
    categories.each do |cat|
      this_task_categories[cat] = true
    end
    return this_task_categories
  end

end
