require 'minitest/autorun'
require './lib/task'
require './lib/task_store'

class TestTask < Minitest::Test

  def setup
    sleep 0.2
    @store = TaskStore.new
    params = {"description" => "", "categories"=>""} # dummy data mimics user input
    @task = Task.new(@store, params)
  end

  # New Task object has attributes: id, position, description, date added,
  # due date, and categories.
  def test_initialize
    refute_nil(@task.id)
    refute_nil(@task.ok)
    refute_nil(@task.message)
    refute_nil(@task.description)
    refute_nil(@task.position)
    refute_nil(@task.date_added)
    refute_nil(@task.date_due)
    refute_nil(@task.categories)
  end

  # given a set of ids (check they're all numerical), determine the highest
  # and then return the numeral of the next number
  def test_assign_id
    bad_sample_ids = [0, 1, 3, 5, "b", 4]
    assert_raises "Invalid ID" do
      assign_id(bad_sample_ids)
    end
    good_sample_ids = [0, 1, 3, 5, 4]
    perfect_sample_ids = [0, 1, 2, 3, 4, 5, 6, 7]
    assert_equal(@task.assign_id(good_sample_ids), 6)
    assert_equal(@task.assign_id(perfect_sample_ids), 8)
  end

  def test_check_description
    # Return error message if description is blank.
    assert_equal(@task.check_description(""),"Description cannot be blank.")
    # Return error message if description is too long.
    assert_equal(@task.check_description("x" * 141), "Description was 141 characters long; cannot exceed 140.")
    # Otherwise return "ok"
    assert_equal(@task.check_description("This is a test."), "ok")
  end

  def test_parse_date
    refute_equal(@task.parse_date("12/1/2016"), "error")
    refute_equal(@task.parse_date("6/30"), "error")
    refute_equal(@task.parse_date("12-1-2016"), "error")
    refute_equal(@task.parse_date("July 1"), "error")
    refute_equal(@task.parse_date("now"), "error")
    refute_equal(@task.parse_date("today"), "error")
    refute_equal(@task.parse_date("tomorrow"), "error")
    refute_equal(@task.parse_date("yesterday"), "error")

    assert_equal(@task.parse_date("13/1"), "error")
    assert_equal(@task.parse_date("1234"), "error")
    assert_equal(@task.parse_date("foo"), "error")
    assert_equal(@task.parse_date(""), "error")
    assert_equal(@task.parse_date(nil), "error")
  end

  def test_categories_validate
    assert(@task.categories_validate("foo"))
    assert(@task.categories_validate("foo bar"))
    refute_equal(@task.categories_validate("0123456789012345678901234"),
      " Category '0123456789012345678901234' was too long.")
    assert_equal(@task.categories_validate("01234567890123456789012345"),
      " Category '01234567890123456789012345' was too long.")
    assert_includes(@task.categories_validate("~"), " Category '~' had weird characters.")
    assert_includes(@task.categories_validate("%"), " Category '%' lacks a letter or digit.")
    refute_equal(@task.categories_validate("?, ?"), " Category '?' had weird characters. Category '?' lacks a letter or digit. Category ' ?' had weird characters. Category ' ?' lacks a letter or digit.")
  end

  def test_categories_parse
    assert_equal(@task.categories_parse("  yo  , FOO, Bar,  baz, qux
      "), {"yo" => true, "foo" => true, "bar" => true, "baz" => true, "qux" => true} )
    assert_equal(@task.categories_parse("foo, bar, "), {"foo" => true, "bar" => true})
  end

end
