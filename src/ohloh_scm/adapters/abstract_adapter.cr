module OhlohScm::Adapters
	class AbstractAdapter
		property :url, :branch_name, :username, :password, :errors, :public_urls_only
    setter :temp_folder

		def initialize(params=Hash(Nil,Nil).new)
			params.each { |k,v| send(k.to_s + "=", v) if respond_to?(k.to_s + "=") }
		end

		# Handy for test overrides
		def metaclass
			class << self
				self
			end
		end

    # Returns path to the string_encoder binary.
    # For use with inline system commands like `run`.
    def string_encoder
      File.expand_path("../../../../bin/string_encoder", __FILE__)
    end

    def temp_folder
      @temp_folder || "/tmp"
    end
	end
end

require "./abstract/system"
require "./abstract/validation"
require "./abstract/sha1"
require "./abstract/misc"
