module OhlohScm::Adapters
  class BzrAdapter < AbstractAdapter

    # Return the number of commits in the repository following +after+.
    def commit_count(after = nil, trunk_only = false)
      commit_tokens(after, trunk_only).size
    end

    # Return the list of commit tokens following +after+.
    def commit_tokens(after = nil, trunk_only = false)
      commits(after, trunk_only).map(&.token)
    end

    # Returns a list of shallow commits (i.e., the diffs are not populated).
    # Not including the diffs is meant to be a memory savings when
    # we encounter massive repositories.  If you need all commits
    # including diffs, you should use the each_commit() iterator,
    # which only holds one commit in memory at a time.
    def commits(after = nil, trunk_only = false)
      log = run("#{rev_list_command(after, trunk_only)} | cat")
      a = OhlohScm::Parsers::BzrXmlParser.parse(log)

      if after && (i = a.index { |commit| commit.token == after })
        a[(i+1)..-1]
      else
        a
      end
    end

    # Returns a single commit, including its diffs
    def verbose_commit(token)
      log = run("cd '#{self.url}' && bzr xmllog --show-id -v --limit 1 -c #{to_rev_param(token)}")
      OhlohScm::Parsers::BzrXmlParser.parse(log).first
    end

    # Yields each commit after +after+, including its diffs.
    # The log is stored in a temporary file.
    # This is designed to prevent excessive RAM usage when we
    # encounter a massive repository.  Only a single commit is ever
    # held in memory at once.
    def each_commit(after = nil, trunk_only = false)
      skip_commits = !!after # Don't emit any commits until the 'after' resume point passes

      open_log_file(after, trunk_only) do |io|
        OhlohScm::Parsers::BzrXmlParser.parse(io) do |commit|
          yield remove_directories(commit) unless skip_commits
          skip_commits = false if commit.token == after
        end
      end
    end

    # Ohloh tracks only files, not directories. This function removes directories
    # from the commit diffs.
    def remove_directories(commit)
      commit.diffs.reject! { |d| d.path.to_s[-1..-1] == "/" }
      commit
    end


    # Not used by Ohloh proper, but handy for debugging and testing
    def log(after = nil, trunk_only = false)
      run "#{rev_list_command(after, trunk_only)} -v"
    end

    # Returns a file handle to the log.
    # In our standard, the log should include everything AFTER
    # +after+. However, bzr doesn't work that way; it returns
    # everything after and INCLUDING +after+. Therefore, consumers
    # of this file should check for and reject the duplicate commit.
    def open_log_file(after, trunk_only)
      begin
        if after == head_token # There are no new commits
          # As a time optimization, just create an empty
          # file rather than fetch a log we know will be empty.
          File.open(log_filename, "w") { |f| f.puts %(<?xml version="1.0"?>) }
        else
          run "#{rev_list_command(after, trunk_only)} -v > #{log_filename}"
        end
        File.open(log_filename, "r") { |io| yield io }
      ensure
        File.delete(log_filename) if File.exists?(log_filename)
      end
    end

    def log_filename
      File.join(temp_folder, (self.url).gsub(/\W/,"") + ".log")
    end

    # Uses xmllog command for output to be used by BzrXmlParser.
    private def rev_list_command(after, trunk_only)
      trunk_only_opts = trunk_only ? "--levels=1" : "--include-merges"
      "cd '#{url}' && bzr xmllog --show-id --forward #{trunk_only_opts} -r #{to_rev_param(after)}.."
    end
  end
end
