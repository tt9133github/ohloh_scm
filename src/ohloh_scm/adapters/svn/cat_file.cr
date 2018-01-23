module OhlohScm::Adapters
  class SvnAdapter < AbstractAdapter
    def cat_file(commit, diff)
      cat(diff.path, commit.token)
    end

    def cat_file_parent(commit, diff)
      token = commit.token.try(&.to_i) || 0
      cat(diff.path, token - 1)
    end

    def cat(path, revision)
      begin
        run "svn cat --trust-server-cert --non-interactive -r #{revision} '#{SvnAdapter.uri_encode(File.join(self.root, self.branch_name.to_s, path.to_s))}@#{revision}'"
      rescue
        # FIXME: raise unless $!.message =~ /svn:.*Could not cat all targets because some targets (don't exist|are directories)/
      end
    end
  end
end
