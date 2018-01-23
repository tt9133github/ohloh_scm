module OhlohScm::Adapters
  class GitAdapter < AbstractAdapter
    @dtag_sha_and_names : Array(Array(String)) | Nil

    def git_path
      File.join(self.url, "/.git")
    end

    def exist?
      begin
        !!(head_token)
      rescue
        # FIXME: logger.debug { $! }
        false
      end
    end

    def export(dest_dir, commit_id = "HEAD")
      run "cd #{url} && git archive #{commit_id} | tar -C #{ dest_dir } -x"
    end

    def ls_tree(token="HEAD")
      run("cd #{url} && git ls-tree -r #{token} | cut -f 2 -d '\t'").split("\n", remove_empty: true)
    end

    # For a given commit ID, returns the SHA1 hash of its tree
    def get_commit_tree(token="HEAD")
      run("cd #{url} && git cat-file commit #{token} | grep '^tree' | cut -d ' ' -f 2").strip
    end

    # Moves us the correct branch and checks out the most recent files.
    #
    # Anything not tracked by Git is deleted.
    #
    # This method may not seem like the most efficient way to accomplish this,
    # but we need very high reliability and this sequence gets the job done every time.
    def checkout
      if File.exists? git_path
        run "cd '#{url}' && git clean -f -d -x"
        if self.has_branch?
          run "cd '#{url}' && git reset --hard #{self.branch_name} --"
          run "cd '#{url}' && git checkout #{self.branch_name} --"
        end
      end
    end

    #---------------------------------------------------------------------------
    # BRANCH-RELATED CODE
    #-------------------------------------------------------------------------

    # Returns an array of all branch names
    def branches
      run("cd '#{self.url}' && git branch | #{ string_encoder }" ).split.map { |b| b.match(/\b(.+)$/).try &.[1] }.compact
    end

    def has_branch?(name=self.branch_name)
      return false unless File.exists?(self.git_path)
      self.branches.includes?(name)
    end

    # Create a new local branch to mirror the remote one
    # If a branch of this name already exist, nothing happens.
    def create_tracking_branch(name)
      return if name.to_s == ""

      unless self.branches.includes? name
        run "cd '#{self.url}' && git branch -f #{name} origin/#{name}"
      end
    end

    def is_merge_commit?(commit)
      parent_tokens(commit).size > 1
    end

    def no_tags?
      run("cd #{ url } && git tag | head -1").empty?
    end

    def tags
      return Array(Array(String | Time)).new if no_tags?
      tag_strings = run("cd #{url} && git tag --format='%(creatordate:iso-strict) %(objectname) %(refname)' | sed 's/refs\\/tags\\///'").split(/\n/, remove_empty: true)
      tag_strings.map do |tag_string|
        timestamp_string, commit_hash, tag_name = tag_string.split(/\s/)
        [tag_name, dereferenced_sha(tag_name) || commit_hash, time_object(timestamp_string)]
      end
    end

    private def dereferenced_sha(tag_name)
      dtag_sha_and_name = dtag_sha_and_names.find { |sha_and_name| sha_and_name.last == tag_name }
      dtag_sha_and_name.first if dtag_sha_and_name
    end

    private def dtag_sha_and_names
      @dtag_sha_and_names ||= dereferenced_tag_strings.map(&.split)
    end

    private def dereferenced_tag_strings
      # Pattern: b6e9220c3cabe53a4ed7f32952aeaeb8a822603d refs/tags/v1.0.0^{}
      run("cd #{url} && git show-ref --tags -d | grep '\\^{}' | sed 's/\\^{}//' | sed 's/refs\\/tags\\///'").split(/\n/, remove_empty: true)
    end

    private def time_object(timestamp_string)
      return Time.epoch(0) if timestamp_string.strip.empty?
      Time.parse(timestamp_string, "%FT%T%:z")
    end
  end
end
