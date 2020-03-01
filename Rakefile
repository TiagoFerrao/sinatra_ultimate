require "rake/testtask" # load Rake's specialized task for running tests
# UNCOMMENT OUT THE FOLLOWING LINES IN LINUX TO CHECK COVERAGE!
# require 'simplecov'
# SimpleCov.start

Rake::TestTask.new(:test) do |t| # set up a task named 'test'
  t.test_files = FileList['test/**/test_*.rb'] # run all files in "test"
end

task :default => [:test]
