module OhlohScm::Adapters
  class HgAdapter < AbstractAdapter

    # Return the number of commits in the repository following +after+.
    def commit_count(after = 0, up_to = :tip, trunk_only = false)
      commit_tokens(after, up_to, trunk_only).size
    end

    # Return the list of commit tokens following +after+.
    def commit_tokens(after = 0, up_to = :tip, trunk_only = false)
      hg_log_with_opts, after = hg_command_builder(after, up_to, trunk_only)
      # We reverse the final result in Ruby, rather than passing the --reverse flag to hg.
      # That's because the -f (follow) flag doesn't behave the same in both directions.
      # Basically, we're trying very hard to make this act just like Git. The hg_rev_list_test checks this.
      tokens = run("cd '#{self.url}' && #{ hg_log_with_opts } --template='{node}\\n'").split("\n", remove_empty: true).reverse

      # Hg returns everything after *and including* after.
      # We want to exclude it.
      if tokens.any? && tokens.first == after
        tokens[1..-1]
      else
        tokens
      end
    end

    # Returns a list of shallow commits (i.e., the diffs are not populated).
    # Not including the diffs is meant to be a memory savings when we encounter massive repositories.
    # If you need all commits including diffs, you should use the each_commit() iterator, which only holds one commit
    # in memory at a time.
    def commits(after = 0, up_to = :tip, trunk_only = false)
      hg_log_with_opts, after = hg_command_builder(after, up_to, trunk_only)

      log = run("cd '#{self.url}' && #{ hg_log_with_opts } --style #{OhlohScm::Parsers::HgStyledParser.style_path}")
      a = OhlohScm::Parsers::HgStyledParser.parse(log).reverse

      if a.any? && a.first.token == after
        a[1..-1]
      else
        a
      end
    end

    # Returns a single commit, including its diffs
    def verbose_commit(token)
      log = run("cd '#{self.url}' && hg log -v -r #{token} --style #{OhlohScm::Parsers::HgStyledParser.verbose_style_path} | #{ string_encoder }")
      OhlohScm::Parsers::HgStyledParser.parse(log).first
    end

    # Yields each commit after +after+, including its diffs.
    # The log is stored in a temporary file.
    # This is designed to prevent excessive RAM usage when we encounter a massive repository.
    # Only a single commit is ever held in memory at once.
    def each_commit(after = 0, up_to = :tip, trunk_only = false)
      open_log_file(after, up_to, trunk_only) do |io|
        commits = OhlohScm::Parsers::HgStyledParser.parse(io)
        commits.reverse.each do |commit|
          yield commit if commit.token != after
        end
      end
    end

    # Not used by Ohloh proper, but handy for debugging and testing
    def log(after = 0, up_to = :tip, trunk_only = false)
      hg_log_with_opts = hg_command_builder(after, up_to, trunk_only)
      run "cd '#{url}' && #{ hg_log_with_opts } | #{ string_encoder }"
    end

    # Returns a file handle to the log.
    # In our standard, the log should include everything AFTER +after+. However, hg doesn't work that way;
    # it returns everything after and INCLUDING +after+. Therefore, consumers of this file should check for
    # and reject the duplicate commit.
    def open_log_file(after = 0, up_to = :tip, trunk_only = false)
      hg_log_with_opts, after = hg_command_builder(after, up_to, trunk_only)
      begin
        if after == head_token # There are no new commits
          # As a time optimization, just create an empty file rather than fetch a log we know will be empty.
          File.open(log_filename, "w") { }
        else
          run "cd '#{url}' && #{ hg_log_with_opts } --style #{OhlohScm::Parsers::HgStyledParser.verbose_style_path} | #{ string_encoder } > #{log_filename}"
        end
        File.open(log_filename, "r") { |io| yield io }
      ensure
        File.delete(log_filename) if File.exists?(log_filename)
      end
    end

    def log_filename
      File.join(temp_folder, (self.url).gsub(/\W/,"") + ".log")
    end

    private def hg_command_builder(after, up_to, trunk_only)
      after ||= 0
      up_to ||= :tip

      options = if trunk_only
        "--follow-first -r #{ up_to }:#{ after }"
      else
        query = "and (branch(#{ branch_name }) or ancestors(#{ branch_name }))" if branch_name && branch_name != "default"
        "-r '#{ up_to }:#{ after } #{ query }'"
      end

      ["hg log -f -v #{ options }", after]
    end
  end
end
