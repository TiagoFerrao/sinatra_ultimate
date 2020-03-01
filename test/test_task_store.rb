require 'minitest/autorun'
require './lib/task_store'

class TestTaskStore < Minitest::Test

  def setup
    sleep 0.2
    @my_store = TaskStore.new
    @my_own_store = TaskStore.new(101)
  end

  def test_initialize
    assert_match(/\/tmp\//, @my_store.path) # a /tmp/ path has been called
    assert_equal(@my_own_store.path,"./userdata/101.yml")
  end

  def test_determine_path
    # if an ID is passed, I'll get back /userdata/<id>
    assert_equal(@my_store.determine_path(123),"./userdata/123.yml")
    # if no ID is passed, I'll get back /tmp/<something>
    assert_match(/.\/tmp\/\d*.yml/, @my_store.determine_path)
  end

  def test_delete_path
    @my_store.delete_path
    assert_nil(@my_store.path)
  end

end
