module OhlohScm::Adapters
	class BzrlibAdapter < BzrAdapter

		def cat(revision, path)
      bzr_client.cat_file(revision, path)
		end

	end
end
