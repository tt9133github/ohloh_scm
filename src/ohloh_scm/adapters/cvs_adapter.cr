module OhlohScm::Adapters
	class CvsAdapter < AbstractAdapter
		property :module_name

		def english_name
			"CVS"
		end

		def initialize(params={})
			super
			@module_name = params[:module_name]
		end
	end
end

require "./cvs/validation"
require "./cvs/commits"
require "./cvs/misc"
