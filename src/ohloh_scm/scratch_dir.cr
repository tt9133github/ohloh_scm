require "fileutils"

# A utility class to manage the creation and automatic cleanup of temporary directories.
module OhlohScm
  class ScratchDir
    getter :path
    @path : String

    # Creates a uniquely named directory in the system tmp directory.
    #
    # If a block is passed to the constructor, the path to the created directory
    # will be yielded to the block. The directory will then be deleted
    # when this block returns.
    #
    # Sample usage:
    #
    #   ScratchDir.new do |path|
    #     # Do some work in the new directory
    #     File.new( path + "/foobaz", "w" ) do
    #       # ...
    #     end
    #   end # Scratch directory is deleted here
    #
    def initialize
      @path = `mktemp -d /tmp/ohloh_scm_XXXXXX`.strip
    end

    def initialize(&block)
      @path = `mktemp -d /tmp/ohloh_scm_XXXXXX`.strip
      begin
        return yield(@path)
      ensure
        FileUtils.rm_rf(@path)
      end
    end
  end
end
