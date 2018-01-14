require "test/unit"
require "fileutils"
require "find"

unless defined?(TEST_DIR)
  TEST_DIR = File.dirname(__FILE__)
end
require "../lib/ohloh_scm"

OhlohScm::Adapters::AbstractAdapter.logger = Logger.new(File.open("log/test.log","a"))

unless defined?(REPO_DIR)
  REPO_DIR = File.expand_path(File.join(TEST_DIR, "repositories"))
end

unless defined?(DATA_DIR)
  DATA_DIR = File.expand_path(File.join(TEST_DIR, "data"))
end

class OhlohScm::Test < Test::Unit::TestCase
  # For reasons unknown, the base class defines a default_test method to throw a failure.
  # We override it with a no-op to prevent this 'helpful' feature.
  def default_test
  end
end
