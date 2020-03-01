=begin
todo.rb is a basic to do list program to practice hashes, file processing, etc.

While it will run on the command line, it will have a variety of functions.
The basic object is the task. A task is assigned with a timestamp (so I'll
have to learn about time processing in Ruby), will have an editable content,
will be deletable, will be movable, etc. Tasks will be assigned to classes:
unfinished and finished. The classes will have functions for listing, moving
from one class to the other, etc. More advanced features might include such
things as adding due dates, posting warnings, etc.

I can use a hash constructor method to initialize tasks, including timestamps,
text, due date, and tags.
=end

# ###########################
# Task - the basic class
# ###########################
class Task
  attr_accessor :time, :text, :due
  def initialize
    create_new_task unless text && due
    self.time = Time.new
    self.text = text
    self.due = due
    save_task
  end

  def create_new_task
    print "Enter task description: "
    self.text = gets.chomp
    print "Enter due date: "
    self.due = gets.chomp
  end

  def save_task
    # Prepare line for writing
    new_task_array = [self.time, self.text, self.due]
    new_task_line = new_task_array.join("|")
    # Append it
    File.open("todo.txt", "a") do |data_holder|
      data_holder << new_task_line + "\n"
    end
    print_task
    $my_list.load_tasks # need to reload tasks after new was saved
  end

  def print_task
    puts "Saved:\n#{text} |Due: #{due} |Added: #{time}"
  end
end # End of Task class def.

# ToDoList
# ###########################
# This is simply a list object, used to perform general list functions.
# Loaded upon program loading, and updated after each edit.
# ###########################
class ToDoList
  attr_accessor :tasks
  # A new ToDoList object contains all the tasks and their data, for
  # easy listing and references for deleting. If no items exist yet,
  # the list is blank.
  def initialize
    load_tasks
  end

  def load_tasks
    # Open data and save.
    task_lines = []
    self.tasks = []
    File.open("todo.txt") do |data_holder|
      task_lines = data_holder.readlines
    end
    # Construct array (list) of hash objects (tasks)
    task_lines.each do |line|
      line.chomp!
      task_hash = {time: line.split("|")[0],
        text: line.split("|")[1],
        due: line.split("|")[2]
      }
      # Append each line's hash to the array
      self.tasks << task_hash
    end
  end

  # Plan: read task list into array; pretty-format and print
  def list_tasks
    unless tasks
      puts "No tasks yet. Add one!"
      return
    end
    # Pretty-format hash and print
    print "     " + "ITEM".ljust(30) + " | " +
      "WHEN DUE".ljust(15) + " | " +
      "WHEN ADDED".ljust(15) + "\n"
    tasks.each do |task|
      print "<#{tasks.find_index(task) + 1}>".ljust(5) +
        task[:text].ljust(30) + " | " +
        task[:due].ljust(15) + " | " +
        task[:time].ljust(15) + "\n"
    end
  end

  def delete_task
    puts "Delete which number?"
    delete_num = gets.to_i
    if delete_num < 1 || delete_num > $my_list.tasks.length
      puts "Invalid input."
      return
    end
    $my_list.tasks.delete_at(delete_num - 1)
    save_all_tasks
    $my_list.list_tasks
    puts "Deleted."
  end

  def save_all_tasks
    # Embarrassing...duplicate code. Not sure how to fix.
    lines_to_write = []
    $my_list.tasks.each do |task|
      new_task_array = [task[:time], task[:text], task[:due]]
      new_task_line = new_task_array.join("|")
      lines_to_write << new_task_line
    end
    # Overwrite file
    File.open("todo.txt", 'w') do |data_holder|
      lines_to_write.each do |line|
        data_holder << line + "\n"
      end
    end
  end # End of save_all_tasks

end

#######################################
# General methods
#######################################
# Does choice occur among approved commands?
def verify_choice_ok (choice)
  if "adehlnq+?".include? (choice)
    return true
  else
    return false
  end
end

# Strictly gets a valid user choice and returns it
def get_valid_user_choice
  choice_ok = false
  choice = ""
  until choice_ok
    print "> "
    choice = gets.chomp
    choice_ok = verify_choice_ok(choice)
    puts "Invalid choice." unless choice_ok
  end
  return choice
end

def print_help
  puts "Instructions:"
  puts "a or n: ".rjust(14) + "add task"
  puts "l: ".rjust(14) + "list tasks"
  puts "d: ".rjust(14) + "delete a task"
  puts "h or ?: ".rjust(14) + "help"
  puts "e or q: ".rjust(14) + "exit"
end

#################################################
# Welcome, startup, & command prompt for program
#################################################
welcome = "Welcome to Sanger's Simple To Do List Program!"
puts "=" * welcome.length
puts welcome
puts "=" * welcome.length
print_help
$my_list = ToDoList.new
letsgo = 1
while (letsgo == 1)
  choice = get_valid_user_choice
  case (choice)
    when "h", "?" then print_help
    when "n", "a", "+" then Task.new
    when "e", "q" then letsgo = 0
    when "l" then $my_list.list_tasks
    when "d" then $my_list.delete_task
  end
end
puts "Goodbye!"
