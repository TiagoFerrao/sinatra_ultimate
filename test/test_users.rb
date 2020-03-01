ENV['RACK_ENV'] = 'test'
require 'rack/test'
require 'minitest/autorun'
require_relative "../todo"
require './lib/users'

class TestUsers < Minitest::Test
  include Rack::Test::Methods
  def app
    Sinatra::Application
  end

  def setup
    sleep 0.2
    @users = UserStore.new('users.yml')
    # change this up below by substituting datas
    @sample_user = {email: "god@gmail.com", password: "password5",
      password_again: "password5", pg_type: "index"}
  end

  def test_submit_new_account
    # SUCCESS VALIDATION
    post '/submit_new_account', params = @sample_user
    follow_redirect!
    assert last_response.ok?
    # should be on / and success message should be spotted
    assert last_response.body.include?("<h1>Simple To Do List</h1>")
    assert last_response.body.include?("You are now logged in!")
    # teardown this user
    teardown_user = @users.all.find {|user| user.email == @sample_user[:email]}
    @users.delete_forever(teardown_user.id) if teardown_user
    sleep 0.2

    # EMAIL VALIDATION
    # error messages don't appear when input validates
    post '/submit_new_account', params = @sample_user
    follow_redirect!
    assert last_response.ok?
    refute last_response.body.include?("Sorry, check the email address.")
    refute last_response.body.include?("Password must have at least 8 characters.")
    refute last_response.body.include?("Sorry, those passwords don't match. Try again.")
    # teardown this user
    teardown_user = @users.all.find {|user| user.email == @sample_user[:email]}
    @users.delete_forever(teardown_user.id) if teardown_user
    sleep 0.2
    # if email doesn't validate, appropriate message appears on page...
    @sample_user[:email] = "foo, this ain't an email address!"
    post '/submit_new_account', params = @sample_user
    follow_redirect!
    assert last_response.body.include?("Sorry, check the email address.")
    # ...and bad email attempt also reappears
    assert last_response.body.include?(@sample_user[:email])
    # but email disappears after that (on page refresh)
    get '/create_account'
    refute last_response.body.include?(@sample_user[:email])
    # and message disappears after that
    refute last_response.body.include?("Sorry, check the email address.")

    # EMAIL DUPLICATES HANDLED
    # error messages don't appear when no duplicate is spotted
    @sample_user[:email] = "god@gmail.com" # fix bad tester for new test
    post '/submit_new_account', params = @sample_user
    follow_redirect!
    refute last_response.body.include?("That email has an account already. "\
      "<a href=\"/login\">Login?</a>")
    # attempt to create account again!
    post '/submit_new_account', params = @sample_user
    follow_redirect!
    # if duplicate spotted, appropriate message appears on page...
    assert last_response.body.include?("That email has an account already. "\
      "<a href=\"/login\">Login?</a>")
    # and message (and email) disappears after that
    get '/create_account'
    refute last_response.body.include?("That email has an account already. "\
      "<a href=\"/login\">Login?</a>")
    # teardown this user
    teardown_user = @users.all.find {|user| user.email == @sample_user[:email]}
    @users.delete_forever(teardown_user.id) if teardown_user
    sleep 0.2

    # PASSWORD VALIDATION
    @sample_user[:password] = "asd3f"
    post '/submit_new_account', params = @sample_user
    follow_redirect!
    # if password doesn't validate, appropriate message appears...
    assert last_response.body.include?("Password must have at least 8 characters.")
    # but email address does
    assert last_response.body.include?(@sample_user[:email])
    # password doesn't appear on page
    refute last_response.body.include?(@sample_user[:password])
    # but message disappears after that (on page refresh)
    get '/create_account'
    refute last_response.body.include?("Password must have at least 8 characters.")

    # PASSWORD INSTANCES MATCH (don't validate second one)
    @sample_user[:password] == "password5" # fix bad tester for new test
    post '/submit_new_account', params = @sample_user
    follow_redirect!
    # if passwords don't match, appropriate message appears...
    assert last_response.body.include?("Sorry, those passwords don't match. Try again.")
    # ...but message disappears after that (on page refresh)
    get '/create_account'
    refute last_response.body.include?("Sorry, those passwords don't match. Try again.")
  end

  def test_login
    get '/login'
    assert last_response.ok?
    # login page form should have the action '/submit_login' & no error
    assert last_response.body.include?("")
    refute last_response.body.include?("Sorry, that email and password don't work.")
  end

  def test_submit_login
    # LOGIN WORKS
    # someone who logs in having started from a certain pg_type should return to
    # that pg_type
    # first create test account
    post '/submit_new_account', params = @sample_user
    # Note, not following redirect above; but now, login
    post "/submit_login", params = @sample_user
    follow_redirect!
    # this should land the user on the page he started from
    assert last_response.body.include?("<h1>Simple To Do List</h1>")
    # and he should see the "login" message
    assert last_response.body.include?("You are now logged in!")
    # and his email address!
    assert last_response.body.include?(@sample_user[:email].slice(0..(@sample_user\
       [:email].index('@') - 1)))
    # and 'log out'!
    assert last_response.body.include?("Logout</button>")
    # teardown test account
    teardown_user = @users.all.find {|user| user.email == @sample_user[:email]}
    @users.delete_forever(teardown_user.id) if teardown_user
    sleep 0.2
    # login page should return error if email & password aren't in users.yml
    post "/submit_login", params = {email: "jkkdoalk@asdkflkjsadl.wmx",
      password: "asdf1234"}
    follow_redirect!
    assert last_response.body.include?("Sorry, that email and password don't work.")
  end

  def test_logout
    # first, create an account and log in
    post '/submit_new_account', params = @sample_user
    follow_redirect!
    post '/submit_login', params = @sample_user
    follow_redirect!
    post '/logout' # no params
    follow_redirect!
    assert last_response.body.include?("Create Account!")
    refute last_response.body.include?(@sample_user[:email].slice(0..\
      (@sample_user[:email].index('@') - 1)))
    assert last_response.body.include?("Login</button>")
    refute last_response.body.include?("Logout</button>")
    # teardown test account
    teardown_user = @users.all.find {|user| user.email == @sample_user[:email]}
    @users.delete_forever(teardown_user.id) if teardown_user
    sleep 0.2
  end

  def teardown
  end

end
