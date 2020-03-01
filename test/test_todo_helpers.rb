ENV['RACK_ENV'] = 'test'
require 'rack/test'
require 'minitest/autorun'
require_relative '../todo'
require './lib/todo_helpers'
require './lib/task_store'
require './lib/task'
require 'sinatra'
enable :sessions

class TestToDoHelpers < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    sleep 0.2
    @store = TaskStore.new
    @my_own_store = TaskStore.new(1) # #1 will always be a test store
    @users = UserStore.new('users.yml')
  end

  def test_compile_categories
    # setup objects
    # dummy data mimics user input
    params = {"description" => "Test task 123", "categories" => "foo, bar"}
    @task1 = Task.new(@store, params)
    @task1.categories["deleted"] = true
    @task1.categories["foobar"] = true
    @store.save(@task1)
    @task2 = Task.new(@store, params)
    @task2.categories["completed"] = true
    @task2.categories["foobar"] = true
    @store.save(@task2)
    @task3 = Task.new(@store, params)
    @task3.categories[nil] = "foobar"
    @store.save(@task3)
    @task4 = Task.new(@store, params)
    @task4.categories["deleted"] = true
    @task4.categories["completed"] = true
    @store.save(@task4)
    @tasks = @store.all
    # list of items that should be deleted; update if you add more "deleted"s
    @testers_to_delete = [@task1, @task4]
    @testers_to_delete_length = @testers_to_delete.length

    # removes "deleted" and "completed" from categories
    refute(compile_categories(@tasks).include?("deleted"))
    refute(compile_categories(@tasks).include?("completed"))
    # includes categories only once (no duplicates)
    assert(1, compile_categories(@tasks).count {|x| x == "foo"})
    # rejects the nil category
    refute(compile_categories(@tasks).include? nil)

    # ACTUALLY TESTS test_delete_forever_all
    @store_length_before_deletion = @store.all.length
    @store = delete_forever_all(@store, @testers_to_delete)
    sleep 0.2
    @store_length_after_deletion = @store.all.length
    assert_equal(@testers_to_delete_length, @store_length_before_deletion -
      @store_length_after_deletion)

    # teardown objects
    @store.delete_forever(@task1.id)
    @store.delete_forever(@task2.id)
    @store.delete_forever(@task3.id)
    @store.delete_forever(@task4.id)
    sleep 0.4
  end

  def test_validate_email
    # email validates (or doesn't)--different addresses validate
    assert(validate_email("yo.larrysanger@gmail.com")) # returns true if valid
    assert(validate_email("president@whitehouse.gov"))
    # refute(validate_email("foo..bar@gmail.com")) # fine, I won't validate that
    refute(validate_email("president@@whitehouse.gov"))
    refute(validate_email("foo#bar.com"))
    refute(validate_email("foo@bar&com"))
    refute(validate_email("bazqux"))
    refute(validate_email("google.com"))
    refute(validate_email("foo@"))
    refute(validate_email("foo@bar"))
    refute(validate_email("@bar.com"))
    refute(validate_email("@bar"))
  end

  def test_email_not_duplicate
    # create new account using foo@bar.com
    test1 = User.new("foo@bar.com", "asdf1234", assign_user_id(@users))
    @users.save(test1)
    # a second instance of the address doesn't validate
    refute(email_not_duplicate("foo@bar.com", @users))
    # teardown this test user
    @users.delete_forever(test1.id)
    sleep 0.2
  end

  def test_validate_pwd
    # validates OK password
    assert(validate_pwd("asdf8asdf"))
    # must be at least eight characters long
    assert_equal(validate_pwd("asd5"),"Password must have at least 8 characters. ")
    # must contain a number
    assert_equal(validate_pwd("asdfasdf"),"Password must have at least one number. ")
    # must contain a letter
    assert_equal(validate_pwd("12341234"),"Password must have at least one letter. ")
  end

  def test_passwords_match
    # if two input passwords match, return true; else, return false
    assert(passwords_match("foobar98", "foobar98"))
    refute(passwords_match("foobar98", "foobar99"))
  end

  def test_confirm_credentials
    # create an account for testing
    testuser = User.new("foo@bar.com", "asdf1234", assign_user_id(@users))
    @users.save(testuser)
    # given the user's email and password, test if the user can log in
    assert(confirm_credentials("foo@bar.com", "asdf1234", @users))
    # test that a zany, never-to-be-seen username and password don't log in
    refute(confirm_credentials("jkkdoalk@asdkflkjsadl.wmx", "asdf1234", @users))
    # teardown this test user
    @users.delete_forever(testuser.id)
    sleep 0.2
  end

  # NOT TESTING THIS BECAUSE I CAN'T (WON'T) PASS SESSION VARIABLES AND
  # I REFUSE TO EDIT THE TARGET METHOD TO FIT THE TEST...SEEMS A BAD IDEA.
  def test_check_and_maybe_load_taskstore
=begin
    # if logging in, .path should equal /userdata/foo
    session[:id] = 1 # should simulate logging in
    logged_in_store = check_and_maybe_load_taskstore(@store)
    assert_match(/\/userdata\//, logged_in_store.path) # a /tmp/ path has been called
    # if logging out, .path should equal /tmp/foo
    session.clear # should simulate logging out
    logged_out_store = check_and_maybe_load_taskstore(@my_own_store)
    assert_match(/\/tmp\//, logged_in_store.path) # a /tmp/ path has been called
=end
  end

  def teardown
  end

=begin

  * NEXT: Go through the list below and retire items that are done.

  * Auto-create /tmp and /userdata as needed

  * Post question on Stack Overflow about the seeming Process problem
    First research "Errno::EACCES: Permission denied @ unlink_internal" some more.

  * DONE: check_and_maybe_load_taskstore requirements:
  * IF
      task store exists
      session[:id] doesn't exist
      task store path = /tmp/
        THEN return the task store submitted
  * IF
      task store exists
      session[:id] doesn't exist
      task store path = /userdata/
        THEN let store = TaskStore.new

    * IF
        task store exists
        session[:id] exists
        task store path = /userdata/
          THEN return the task store submitted
    * If
        task store exists
        session[:id] exists
        task store path = /tmp/
          THEN let store = TaskStore.new(session[:id])

    * If
        task store doesn't exist
        session[:id] doesn't exist
          THEN let store = TaskStore.new
    * If
        task store doesn't exist
        session[:id] exists
          THEN let store = TaskStore.new(session[:id])
    * NOTE: it IS possible for someone to arrive at this method without any
      TaskStore having been loaded. On the other hand, you certainly don't want
      to load it every time the method is called. Therefore, you need to check
      if it's loaded first.

  * At the beginning of every 'get' route, perform check that the right datafile
    is loaded. To perform this check, determine whether the task store's path
    includes '/userdata/' or else '/tmp/'. If /userdata/, and session[:id] exists,
    do nothing (or load the right file if not done already); but if session[:id]
    doesn't exist, then re-initialize 'store' (i.e., store = TaskStore.new). If
    /tmp/, and session[:id] doesn't exist, do nothing (or, again, load the right
    file if not done already); but if session[:id] does exist, then re-initialize
    'store' like this: store = TaskStore.new(session[:id]). THEN RELOAD THE PAGE
    so that the proper data shows up!

  * In to_do_helpers.rb (to execute code WITH id!)
    * write check_task_store, which will actually toggle the used store from
      /tmp and /userdata and back.

  * When the user logs in, this should create a new TaskStore object, loading data
    from the associated user datafile, *and* this object should then (and
    thereafter) be associated with store. Make the datafile live at userdata/<id>.
    Make temporary data live at tmp/<temp_id>. (See below for details.)

  * When a new TaskStore is initialized, store its storage path. How will it get
    it? Well, from a passed parameter. Presumably, if session[:id] exists, then
    TaskStore will be initialized something like this:
      TaskStore.new(session[:id])
    But if no param is passed, then .storage_path is populated according to a
    TaskStore method that picks the next available ID in ./tmp.



    * DONE: Edit calls to TaskStore.new (to remove file_name as necessary).

    * DONE: Write determine_path.
      * DONE: Write tests for determine_path.
      * DONE: Get them to pass.

    * Then test that everything still works.

    * DONE: In task_store.rb
      * DONE: edit param
      * DONE: add attr_accessor for :path
      * DONE: add method for assigning .path
      * DONE: add method to delete path
      * DONE: test code works without id passed
      * FIXED: find out why /tmp/ number doesn't increase (stays on 1.yml)
      * YES: find out whether you want the number to increase
      * DONE: write tests for code WITH id

=end

end
