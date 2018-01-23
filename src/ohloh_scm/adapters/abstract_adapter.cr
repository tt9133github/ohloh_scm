module OhlohScm::Adapters
  class AbstractAdapter
    property :url, :errors, :temp_folder, :public_urls_only
    property username : StringOrNil
    property password : StringOrNil
    property branch_name : StringOrNil
    property module_name : StringOrNil
    @url : String

    def initialize(@url = "", @branch_name = nil, @module_name = nil, @username = nil, @password = nil, @public_urls_only = false)
      @temp_folder = "/tmp"
      @errors = [] of Array(String) | Nil
    end

    # Returns path to the string_encoder binary.
    # For use with inline system commands like `run`.
    def string_encoder
      File.expand_path("../../../../bin/string_encoder", __FILE__)
    end

    def checkout(rev, dest_dir)
    end
  end
end

require "./abstract/system"
require "./abstract/validation"
require "./abstract/sha1"
require "./abstract/misc"
