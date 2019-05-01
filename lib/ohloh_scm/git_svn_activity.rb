module OhlohScm
  class GitSvnActivity < Activity
    def_delegators :scm, :url

    def commit_count(opts={})
      cmd = "#{after_revision(opts)} | grep -E -e '^r[0-9]+.*lines$' | wc -l"
      git_svn_log(cmd: cmd, oneline: false).to_i
    end

    def source_scm_commit_count(opts={})
      options = username_and_password_opts(opts[:source_scm])
      svn_log = run("#{accept_ssl_certificate_cmd} svn info #{options} '#{opts[:source_scm].url}'")
      svn_log.match(/Revision: ([\d]*)/)
      $1.to_i - opts[:after].to_i
    end

    def commits(opts={})
      parsed_commits = []
      open_log_file(opts) do |io|
        parsed_commits = OhlohScm::Parsers::SvnParser.parse(io)
      end
      parsed_commits
    end

    def commit_tokens(opts={})
      cmd = "#{after_revision(opts)} | #{extract_revision_number}"
      git_svn_log(cmd: cmd, oneline: false).split
        .map(&:to_i)
    end

    def each_commit(opts={})
      commits(opts).each do |commit|
        yield commit
      end
    end

    def open_log_file(opts={})
      cmd = "-v #{ after_revision(opts) } | #{string_encoder} > #{log_filename}"
      git_svn_log(cmd: cmd, oneline: false)
      File.open(log_filename, 'r') { |io| yield io }
    end

    def log_filename
      File.join('/tmp', url.gsub(/\W/,'') + '.log')
    end

    def after_revision(opts)
      next_token = opts[:after].to_i + 1
      next_head_token = head_token.to_i + 1
      "-r#{ next_token }:#{ next_head_token }"
    end

    def extract_revision_number
      "grep '^r[0-9].*|' | awk -F'|' '{print $1}' | cut -c 2-"
    end

    def head_token
      cmd = "--limit=1 | #{extract_revision_number}"
      git_svn_log(cmd: cmd, oneline: false)
    end

    def git_svn_log(cmd:, oneline:)
      oneline_flag = '--oneline' if oneline
      run("#{git_svn_log_cmd} #{oneline_flag} #{cmd}").strip
    end

    def accept_ssl_certificate_cmd
      File.expand_path('../../../../../bin/accept_svn_ssl_certificate', __FILE__)
    end

    def username_and_password_opts(source_scm)
      username = source_scm.username.to_s.empty? ? '' : "--username #{ @source_scm.username }"
      password = source_scm.password.to_s.empty? ? '' : "--password='#{@source_scm.password}'"
      "#{username} #{password}"
    end

    def cat_file(commit, diff)
      cat(git_commit(commit), diff.path)
    end

    def cat_file_parent(commit, diff)
      cat("#{ git_commit(commit) }^", diff.path)
    end

    def cat(revision, file_path)
      file_path = %Q{#{file_path}}
      run("cd #{self.url} && git show #{ revision }:#{ file_path.shellescape }").strip
    end

    def git_commit(commit)
      run("cd #{self.url} && git svn find-rev r#{commit.token}").strip
    private

    def git_svn_log_cmd
      "cd #{self.url} && git svn log"
    end
  end
end
