module OhlohScm::Adapters
  class Factory

    # Given a local path on disk, try to guess what kind of repository it is,
    # and return an appropriate adapter.
    def self.from_path(path)

      if File.exists?(File.join(path, ".git"))
        GitAdapter.new(url: File.expand_path(path)).normalize

      elsif File.exists?(File.join(path, ".hg"))
        HgAdapter.new(url: File.expand_path(path)).normalize

      elsif File.exists?(File.join(path, ".bzr"))
        BzrAdapter.new(url: File.expand_path(path)).normalize

      elsif File.exists?(File.join(path, "db"))
        SvnAdapter.new(url: File.expand_path(path)).normalize

      elsif File.exists?(File.join(path, ".svn"))
        # It's a local checkout. Use the secret info stashed by Subversion to find the server URL.
        info = `cd #{path} && svn info`
        if info =~ /^URL: ([^\n]+)$/m
          svn = SvnAdapter.new(url: $1).normalize
          svn.recalc_branch_name
          svn
        end

      elsif File.exists?(File.join(path, "CVS", "Root"))
        # It's a local CVS checkout. Use the secret info to find the server URL.
        root = File.read(File.join(path, "CVS", "Root")).strip
        repo = File.read(File.join(path, "CVS", "Repository")).strip
        #FIXME: CvsAdapter.new(url: root, repository: repo).normalize
        CvsAdapter.new(url: root).normalize
      end
    end
  end
end
