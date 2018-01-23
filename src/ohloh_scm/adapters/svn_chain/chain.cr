module OhlohScm::Adapters
  class SvnChainAdapter < SvnAdapter

    # Returns the entire SvnAdapter ancestry chain as a simple array.
    def chain
      (parent_svn ? parent_svn.as(self).chain : Array(self).new) << self
    end

    # If this adapter's branch was created by copying or renaming another branch,
    # then return a new adapter that points to that prior branch.
    #
    # Only commits following +after+ are considered, so if the copy or rename
    # occured on or before +after+, then no parent will be found or returned.
    def parent_svn(after=0)
      after = after.try(&.to_i) || 0
      @parent_svn ||= Hash(Int32, SvnChainAdapter | Nil).new # Poor man's memoize

      @parent_svn.as(Hash)[after] ||= begin
        parent = nil
        c = first_commit(after)
        if c
          # === Long explanation of real head-scratching bug fix. ===
          #
          # It is possible for some Subversion commits to include *multiple*
          # renames/copies of a source directory. For example:
          #
          #    A /foo (from /trunk:1)
          #    D /foo/my_branch
          #    A /foo/bar (from /trunk:1)
          #    D /trunk
          #
          # If we simply processed these entries in the order given, then
          # we would conclude that /foo/bar/my_branch has parent
          # /trunk/bar/my_branch (because the first A matches) and exit.
          #
          # This is incorrect! We must look for the *longest* A that matches
          # our path, and follow that one. In the example above, the correct
          # parent for /foo/bar/my_branch is /trunk/my_branch.
          #
          # Therefore, we must sort diffs by descending filename length, so
          # that we choose the longest match.
          c.diffs.sort { |a,b| b.path.to_s.size <=> a.path.to_s.size }.each do |d|

            # If this diff actually creates this branch, then a parent is impossible.
            # Stop looking for parents.
            #
            # This check exists because of the following complicated commit:
            # http://dendro.cornell.edu/svn/corina/branches/databasing/src/edu/cornell/dendro@813
            # It's long to explain, but basically a directory is renamed and
            # then our branch is created within it, all in a single commit.
            # Without this check, our code mistakenly thinks there is a parent.
            if diff_creates_branch(d)
              return nil
            end

            if (b = parent_branch_name(d))
              parent = SvnChainAdapter.new(url: File.join(root, b), branch_name: b, username: username,
                                           password: password, final_token: d.from_revision.try(&.to_i)).normalize
              break
            end

          end
        end
        parent
      end
    end

    def first_token(after=0)
      c = first_commit(after)
      c && c.token
    end

    def first_commit(after=0)
      after = after.try(&.to_i) || 0
      @first_commit ||= Hash(Int32, Commit | Nil).new # Poor man's memoize
      @first_commit.as(Hash)[after] ||= OhlohScm::Parsers::SvnXmlParser.parse(next_revision_xml(after)).first?
    end

    # Returns the first commit with a revision number greater than the provided revision number
    def next_revision_xml(after=0)
      return "<?xml?>" if after >= (head_token || 0)
      run %(svn log --trust-server-cert --non-interactive --verbose --xml --stop-on-copy -r #{after+1}:#{final_token || "HEAD"} --limit 1 #{opt_auth} '#{SvnAdapter.uri_encode(File.join(self.root, self.branch_name.to_s))}@#{final_token || "HEAD"}' | #{ string_encoder })
    end

    # If the passed diff represents the wholesale movement of the entire
    # code tree from one directory to another, this method returns the name
    # of the previous directory.
    def parent_branch_name(d)
      if %w(A R).includes?(d.action) && branch_name.to_s[0, d.path.to_s.size] == d.path && d.from_path && d.from_revision
        "#{d.from_path}#{branch_name.to_s[d.path.to_s.size..-1]}"
      end
    end

    # True if the passed diff represents the initial creation of the
    # branch -- not a move or copy from somewhere else.
    def diff_creates_branch(d)
      d.action == "A" && branch_name.to_s[0, d.path.to_s.size] == d.path && !d.from_path
    end
  end
end
