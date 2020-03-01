ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require_relative '../todo'

require './lib/task'
require './lib/task_store'

####################################################

class ToDoTest < Minitest::Test
  include Rack::Test::Methods
  include Process

  def app
    Sinatra::Application
  end

####################################################
# GINORMOUS SETUP METHOD...didn't think hard about this
  def setup
    sleep 0.1
    @store = TaskStore.new
    @tasks = @store.all
    # dummy data mimics user input; tests that user input is saved and displayed
    # groovily
    params = {"description" => "Test task 123", "categories" => "foo, bar"}
    # test tasks for /
    @task0 = Task.new(@store, params)
    @task0.categories["deleted"] = false
    @task0.categories["completed"] = false
    @task0.categories["foo123"] = true
    @store.save(@task0)
    @task1 = Task.new(@store, params)
    @task1.categories["deleted"] = true
    @task1.categories["foobar"] = true
    @store.save(@task1)
    @task2 = Task.new(@store, params)
    @task2.categories["completed"] = true
    @task2.categories["foobar"] = true
    @store.save(@task2)
    params_for_3 = params.merge("date_due" => "1/1/2016")
    @task3 = Task.new(@store, params_for_3)
    @task3.categories[nil] = "foobar"
    @store.save(@task3)
    # test tasks for /completed
    @task4 = Task.new(@store, params)
    @task4.categories["deleted"] = false
    @task4.categories["completed"] = true
    @store.save(@task4)
    @task5 = Task.new(@store, params)
    @task5.categories["deleted"] = true
    @task5.categories["completed"] = true
    @task5.categories["foobar"] = true
    @store.save(@task5)
    params_for_6 = params.merge("description" => "I ain't completed")
    @task6 = Task.new(@store, params_for_6)
    @task6.categories["completed"] = false # so shouldn't show up in /completed
    @task6.categories["foobar"] = true
    @store.save(@task6)
    params_for_7 = params.merge("date_due" => "1/1/2016")
    @task7 = Task.new(@store, params_for_7)
    @task7.categories["completed"] = true
    @task7.categories[nil] = "foobar"
    @store.save(@task7)
    # test tasks for /deleted
    params_for_8 = params.merge("date_due" => "1/1/2016", "description" =>
      "undeleteme mama")
    @task8 = Task.new(@store, params_for_8)
    @task8.categories["completed"] = true
    @task8.categories["deleted"] = true
    @store.save(@task8)
    params_for_9 = params.merge("description" => "Should not show up 9262")
    @task9 = Task.new(@store, params_for_9)
    @task9.categories["completed"] = false
    @task9.categories["deleted"] = false # this one isn't deleted, shouldn't show up
    @task9.categories["foo123"] = true
    @store.save(@task9)
    params_for_10 = {"description" => "I am not a foo task", "categories" => "bar"}
    @task10 = Task.new(@store, params_for_10)
    @task10.categories["completed"] = false
    @task10.categories["deleted"] = false
    @store.save(@task10)
    # Note, based on the above data, the complete list of added drop-down tags
    # (because they are not completed & not deleted) should be as follows
    @drop_down_tags = ["foo", "bar"]
    @first_description_to_display = @store.all.last.description
    @second_description_to_display = @store.all[@store.all.length - 2].description
  end

####################################################
# SLOW TESTS OF MAIN 'get' METHODS
  def test_get_slash
    get '/'
    assert last_response.ok?
    # Test index.erb returns required content
    assert last_response.body.include?("Simple To Do List") # page title correct

    # task checkbox present
    assert last_response.body.include?('<label for="task_checkbox"></label><input '\
      'class="checkbox"')
    assert last_response.body.include?('action="/start_edit/') # edit button present
    assert last_response.body.include?("Test task 123") # description from test task present
    assert last_response.body.include?("2016-01-01") # task's date present
    assert last_response.body.include?('<a href="/category/foo') # category link present
    assert last_response.body.include?("<table") # table present
    assert last_response.body.include?("<th") # header present
    assert last_response.body.include?("<tr") # row present
    assert last_response.body.include?("Add new task") # new task dialogue present
    # placeholders present
    assert last_response.body.include?("What do you have to do?")
    assert last_response.body.include?("Optional: format mm/dd")
    assert last_response.body.include?("Separate by commas")
    # checkbox is unchecked
    assert last_response.body.include?('<form method="post" action="/check_completed/')
    # all categories in setup are shown in the Tags list
    @drop_down_tags.each do |tag|
      assert last_response.body.include?("<a href=\"/category/#{tag}")
    end
    # tasks are reversed; last-saved task is displayed before second-to-last
    assert last_response.body.index(@first_description_to_display) <
      last_response.body.index(@second_description_to_display)
    # number of tasks in "foo123" category appears between parentheses on page
    assert_match(/Foo123\s*\(2\)\s*<\/a>/, last_response.body)
    # login/out form present
    assert_match((/form method=\"get\" action=\"\/login/ ||
      /form method=\"get\" action=\"\/logout/), last_response.body)
  end

  def test_get_completed
    get '/completed'
    assert last_response.ok?
    # Test completed.erb returns required content
    assert last_response.body.include?("Completed!") # page title correct
    # task checkbox present
    assert last_response.body.include?('<label for="task_checkbox"></label><input '\
      'class="checkbox"')
    # description from test task present
    assert last_response.body.include?("Test task 123")
    assert last_response.body.include?("2016-01-01") # task's date present
    # category link present
    assert last_response.body.include?('<a href="/category/foo')
    assert last_response.body.include?("<table") # table present
    assert last_response.body.include?("<th") # header present
    assert last_response.body.include?("<tr") # row present
    # checkbox is checked
    assert last_response.body.include?('<form method="post" action="/uncheck_completed/')
    # non-deleted task doesn't appear
    refute last_response.body.include?("I ain't completed")
    # all categories in setup are shown in the Tags list
    @drop_down_tags.each do |tag|
      assert last_response.body.include?("<a href=\"/category/#{tag}")
    end
    # number of tasks in "foo123" category appears between parentheses on page
    assert_match(/Foo123\s*\(2\)\s*<\/a>/, last_response.body)
    # login/out form present
    assert_match((/form method=\"get\" action=\"\/login/ ||
      /form method=\"get\" action=\"\/logout/), last_response.body)
  end

  def test_get_deleted
    get '/deleted'
    assert last_response.ok?
    # Test deleted.erb returns required content
    assert last_response.body.include?("Deleted items") # page title correct
    # task checkbox present
    assert last_response.body.include?('<label for="task_checkbox"></label><input '\
      'class="checkbox"')
    # description from test task present
    assert last_response.body.include?("Test task 123")
    assert last_response.body.include?("2016-01-01") # task's date present
    # category link present
    assert last_response.body.include?('<a href="/category/foo')
    assert last_response.body.include?("<table") # table present
    assert last_response.body.include?("<th") # header present
    assert last_response.body.include?("<tr") # row present
    # checkbox is checked
    assert last_response.body.include?('<form method="post" action="/uncheck_completed/')
    # non-deleted task doesn't appear
    refute last_response.body.include?("Should not show up 9262")
    # all categories in setup are shown in the Tags list
    @drop_down_tags.each do |tag|
      assert last_response.body.include?("<a href=\"/category/#{tag}")
    end
    # number of tasks in "foo123" category appears between parentheses on page
    assert_match(/Foo123\s*\(2\)\s*<\/a>/, last_response.body)
    # delete all button present
    assert_match(/<input type=\"submit\".*Clear All Permanently/, last_response.body)
    # login/out form present
    assert_match((/form method=\"get\" action=\"\/login/ ||
      /form method=\"get\" action=\"\/logout/), last_response.body)
  end

  def test_get_category
    get '/category/foo'
    assert last_response.ok?
    # Test categories.erb returns required content
    assert last_response.body.include?("<title>Foo") # page title correct
    # task checkbox present
    assert last_response.body.include?('<label for="task_checkbox"></label><input '\
      'class="checkbox"')
    # description from test task present
    assert last_response.body.include?("Test task 123")
    assert last_response.body.include?("2016-01-01") # task's date present
    # category link present
    assert last_response.body.include?('<a href="/category/foo')
    assert last_response.body.include?("<table") # table present
    assert last_response.body.include?("<th") # header present
    assert last_response.body.include?("<tr") # row present
    # checkbox is checked
    assert last_response.body.include?('<form method="post" action="/check_completed/')
    # non-foo task doesn't appear
    refute last_response.body.include?("I am not a foo task")
    # all categories in setup are shown in the Tags list
    @drop_down_tags.each do |tag|
      assert last_response.body.include?("<a href=\"/category/#{tag}")
    end
    # number of tasks in "foo123" category appears between parentheses on page
    assert_match(/Foo123\s*\(2\)\s*<\/a>/, last_response.body)
    # login/out form present
    assert_match((/form method=\"get\" action=\"\/login/ ||
      /form method=\"get\" action=\"\/logout/), last_response.body)
  end

####################################################
# HOLY SHIT, INTEGRATION TESTS!
# (i.e., of 'post' methods)
  # checks whether a certain task, marked completed, is deleted from the page
  # and appears on '/completed'; then, when marked uncompleted from /completed,
  # appears on '/'
  def test_post_check_completed_and_uncompleted_id
    post "/check_completed/#{@task9.id}", params = {pg_type: "index"}
    follow_redirect!
    refute last_response.body.include?("Should not show up 9262")
    get "/completed"
    assert last_response.body.include?("Should not show up 9262")
    post "/uncheck_completed/#{@task9.id}", params = {pg_type: "index"}
    get "/completed"
    refute last_response.body.include?("Should not show up 9262")
    get "/"
    assert last_response.body.include?("Should not show up 9262")
    # a user, who checks an item completed while on a cat page, remains there
    post "/check_completed/#{@task9.id}", params = {pg_type: "category",
      cat_page: "foo"}
    follow_redirect!
    refute last_response.body.include?("Should not show up 9262")
    assert last_response.body.include?("<h1>Foo</h1>")
  end

  # check deleted item disappears from index (and cat page) and then reappears
  # on deleted page
  def test_post_delete_id
    get "/"
    assert last_response.body.include?("I am not a foo task")
    get "/category/bar"
    assert last_response.body.include?("I am not a foo task")
    post "/delete/#{@task10.id}", params = {pg_type: "index"}
    follow_redirect! # returns to /
    assert last_response.body.include?("Deleted task!")
    refute last_response.body.include?("I am not a foo task") #unique description gone
    get "/category/bar"
    refute last_response.body.include?("I am not a foo task") #unique description gone
  end

  # check undeleted item disappears from deletions page and reappears in / and
  # a category page
  def test_post_undelete_id
    get "/"
    refute last_response.body.include?("undeleteme mama")
    get "/category/bar"
    refute last_response.body.include?("undeleteme mama")
    post "/undelete/#{@task8.id}", params = {pg_type: "deleted"}
    follow_redirect!
    refute last_response.body.include?("undeleteme mama")
    assert last_response.body.include?("Undeleted task!")
    get "/completed"
    assert last_response.body.include?("undeleteme mama")
  end

  # check that a task is permanently deleted from /deleted
  def test_post_perma_delete_id
    get "/deleted"
    assert last_response.body.include?("undeleteme mama")
    post "/perma_delete/#{@task8.id}", params = {pg_type: "deleted"}
    follow_redirect!
    refute last_response.body.include?("undeleteme mama")
    # If this were undeleted rather than permadeleted, it would be on /completed.
    # Check that this is false.
    get "/completed"
    refute last_response.body.include?("undeleteme mama")
  end

  # post new task; check that the user message & the description appear
  def test_post_newtask
    post "/newtask", params = {"description" =>
      "Write about quick brown foxes", "categories" => "writing823"}
    @newtask = @task
    follow_redirect!
    assert last_response.body.include?("Task saved")
    assert last_response.body.include?("Write about quick brown foxes")
    assert last_response.body.include?("<a href=\"/category/writing823\">Writing823")
    # writes today's date according to %F
    assert last_response.body.include?("#{Time.new.strftime('%F')}</td>")
  end

  # Tests BOTH /start_edit AND /submit_edit
  # Tests that info to edit appears, as it should, in text boxes. This does *not*
  # test editing on pages other than /index, because that isn't supported yet.
  def test_post_big_edit_tester
    post "/start_edit/#{@task0.id}", params = {pg_type: "index"}
    follow_redirect!
    assert last_response.body.include?("<span class=\"editing\">Editing task!</span>")
    assert last_response.body.include?("autofocus=\"autofocus\">Test task 123</textarea>")
    assert last_response.body.include?("id=\"categories\">foo, bar")
    assert last_response.body.include?("Submit Edit")
    # now test /submit_edit
    post "/submit_edit/#{@task0.id}", params = {pg_type: "index", description: "Goo goo",
      categories: "foo, bar, baz", date_due: "2018-02-20", date_added: "2017-01-01"}
    follow_redirect!
    assert last_response.body.include?("Task saved!")
    assert last_response.body.include?("<a href=\"/category/baz\">Baz</a>")
    assert last_response.body.include?("2018-02-20")
    assert last_response.body.include?("2017-01-01</td>")
    # ensure correct error messages are sent after bad edit
    post "/submit_edit/#{@task0.id}", params = {pg_type: "index", description: "",
      categories: "foo, bar, baz", date_due: "2018-02-20"}
    follow_redirect!
    assert last_response.body.include?("Description cannot be blank.")
    post "/submit_edit/#{@task0.id}", params = {pg_type: "index", description: "Goo goo",
      categories: "foo, bar, baz", date_due: "asdf"}
    follow_redirect!
    assert last_response.body.include?("Due date not saved. Please check the format.")
    post "/submit_edit/#{@task0.id}", params = {pg_type: "index", description: "Goo goo",
      categories: "{|*#}", date_due: "2018-02-20"}
    follow_redirect!
    assert last_response.body.include?("Category '{|*#}' had weird characters.")
    post "/submit_edit/#{@task0.id}", params = {pg_type: "index", description: "Add complete suite of integration tasks, now that you can Add complete suite of integration tasks, now that you can Add complete suite of integration tasks, now that you can",
      categories: "foo, bar, baz", date_due: "2018-02-20"}
    follow_redirect!
    assert last_response.body.include?("Description was 173 characters long; cannot exceed 140.")
  end

  # checks that the "Clear All Permanently" button works
  def test_post_delete_all
    get "/deleted"
    refute_match(/<tbody>\s*<\/tbody>/, last_response.body)
    post "/delete_all"
    follow_redirect!
    assert last_response.body.include?("Deleted all tasks!")
    assert_match(/<tbody>\s*<\/tbody>/, last_response.body)
  end

  # ADD THESE LATER!
  # assert last_response.body.include?("Add new task") # new task dialogue present
  # placeholders present
  # assert last_response.body.include?("What do you have to do?")
  # assert last_response.body.include?("Optional: format mm/dd")
  # assert last_response.body.include?("Separate by commas")

  # NOTE
  # USER ACCOUNT-RELATED TESTS ARE IN test_users.rb
  # INCLUDING TESTS ABOUT RELATED test_todo.rb ROUTE METHODS!


####################################################
# OTHER TESTS
  def test_get_create_account
    get '/create_account'
    assert last_response.ok?
    # title is correct
    assert last_response.body.include?("<h1>Create an Account</h1>")
    # action = /submit_new_account
    assert last_response.body.include?("action=\"/submit_new_account\"")
    # username input present
    assert_match(/<input type=\"text\".*name=\"email\"/, last_response.body)
    # password input present
    assert_match(/<input type=\"password\".*name=\"password\"/, last_response.body)
    # password again input present
    assert_match(/<input type=\"password\".*name=\"password_again\"/, last_response.body)
  end

####################################################
# THE INEVITABLE DESTRUCTION THAT FOLLOWS EMPIRE
# (or else database accumulates cruft)
  def teardown
    # These Task objects were actually saved to the yaml file; they need to be
    # deleted or else they accumulate and are actually shown to the user.
    @store.delete_forever(@task0.id) if @task0.id
    @store.delete_forever(@task1.id) if @task1.id
    @store.delete_forever(@task2.id) if @task2.id
    @store.delete_forever(@task3.id) if @task3.id
    @store.delete_forever(@task4.id) if @task4.id
    @store.delete_forever(@task5.id) if @task5.id
    @store.delete_forever(@task6.id) if @task6.id
    @store.delete_forever(@task7.id) if @task7.id
    @store.delete_forever(@task8.id) if @task8.id
    @store.delete_forever(@task9.id) if @task9.id
    @store.delete_forever(@task10.id) if @task10.id
    @store.delete_forever(0) # used by test_post_newtask
    # delete tmp files made during testing
    (`ls tmp` || "").split("\n").each {|file| `rm "tmp/#{file}"`}
    sleep 0.2
  end

end
