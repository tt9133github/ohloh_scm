module OhlohScm::Parsers
	class ArrayWriter

		property :buffer
		def initialize(buffer=[])
			@buffer = buffer
		end

		def write_preamble(opts = {})
		end

		def write_commit(commit)
			@buffer << commit
		end

		def write_postamble
		end
	end
end
