module OhlohScm::Adapters
  class SvnAdapter < AbstractAdapter
    def patch_for_commit(commit)
      token = commit.token.try(&.to_i) || 0
      parent = token - 1
      run("svn diff --trust-server-cert --non-interactive -r#{parent}:#{commit.token} #{url}")
    end
  end
end
