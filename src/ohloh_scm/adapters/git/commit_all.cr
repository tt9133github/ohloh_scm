module OhlohScm::Adapters
  class GitAdapter < AbstractAdapter

    #---------------------------------------------------------------------------
    # COMMIT-RELATED CODE
    #-------------------------------------------------------------------------

    # Commit all changes in the working directory, using metadata from the passed commit.
    def commit_all(commit=Commit.new)
      init_db
      ensure_gitignore
      write_token(commit.token)

      # Establish the author, email, message, etc. for the git-commit.
      message_filename = set_commit_metadata(commit)

      run "cd '#{self.url}' && git add ."
      if anything_to_commit?
        run "cd '#{self.url}' && git commit -a -F #{message_filename}"
      else
        logger.info { "nothing to commit" }
      end
    end

    # Store all of the commit metadata in the GIT environment variables
    # where they will be picked up by the git-commit command.
    #
    # Commit info is required.
    # Author info is optional, and defaults to committer info.
    def set_commit_metadata(commit)

      ENV["GIT_COMMITTER_NAME"] = commit.committer_name || "[anonymous]"
      ENV["GIT_AUTHOR_NAME"] = commit.author_name || ENV["GIT_COMMITTER_NAME"]

      ENV["GIT_COMMITTER_EMAIL"] = commit.committer_email || ENV["GIT_COMMITTER_NAME"]
      ENV["GIT_AUTHOR_EMAIL"] = commit.author_email || ENV["GIT_AUTHOR_NAME"]

      ENV["GIT_COMMITTER_DATE"] = commit.committer_date.to_s
      ENV["GIT_AUTHOR_DATE"] = (commit.author_date || commit.committer_date).to_s

      # This is a one-off fix for DrJava, which includes some escape characters
      # in one of its Subversion messages. This might lead to a more generalized
      # cleanup of message text, but for now...
      commit.message = commit.message.to_s.gsub(/\\027/,"") if commit.message

      # Git requires a non-empty message
      if commit.message.nil? || commit.message =~ /\A\s*\z/
        commit.message = "[no message]"
      end

      # We need to store the message in a file in case it contains crazy characters
      #    that would corrupt a bash command line.
      File.write(message_filename, commit.message)
      message_filename
    end

    # By hiding the message file inside the .git directory, we
    #    avoid it being found by the commit-all.
    def message_filename
      File.expand_path(File.join(git_path, "ohloh_message"))
    end

    # True if there are pending changes to commit.
    def anything_to_commit?
      run("cd '#{self.url}' && git status | tail -1") =~ /nothing to commit/ ? false : true
    end

    # Ensures that the repository directory exists, and that the git database has been initialized.
    def init_db
      unless File.exists? url
        run "mkdir -p '#{url}'"
      end
      unless File.exists? git_path
        run "cd '#{url}' && git init-db"
      end
    end


    #-------------------------------------------------------------------------
    # GIT IGNORE CODE
    # Ensures that we do not waste storage space on non-source code files
    #-------------------------------------------------------------------------

    IGNORE = [
      ".svn",
      "CVS",
      "*.jar",
      "*.tar",
      "*.gz",
      "*.tgz",
      "*.zip",
      "*.gif",
      "*.jpg",
      "*.jpeg",
      "*.bmp",
      "*.png",
      "*.tif",
      "*.tiff",
      "*.ogg",
      "*.aiff",
      "*.wav",
      "*.mp3",
      "*.au",
      "*.ra",
      "*.m4a",
      "*.pdf",
      "*.mpg",
      "*.mov",
      "*.qt",
      "*.avi",
      "*.xbm"
    ]

    # The .gitignore file will be created if it does not exist.
    # If our desired filespec is not found in .gitignore, it will be appended
    # to the end of .gitignore.
    def ensure_gitignore
      gitignore_filename = File.join(url, ".gitignore")
      ignored_paths = File.exists?(gitignore_filename) ? File.read_lines(gitignore_filename).map(&.chomp) : Array(String).new
      ignorable_paths = (IGNORE - ignored_paths).join("\n")
      File.open(gitignore_filename, "a") { |io| io.puts(ignorable_paths) }
    end
  end
end
