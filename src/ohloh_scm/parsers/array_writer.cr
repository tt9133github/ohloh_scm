module OhlohScm::Parsers
	class ArrayWriter

		property :buffer
		def initialize(buffer=Array(OhlohScm::Commit).new)
			@buffer = buffer
		end

		def write_preamble(opts = Hash(Nil,Nil).new)
		end

		def write_commit(commit)
			@buffer << commit
		end

		def write_postamble
		end
	end
end
