# frozen_string_literal: true

module OhlohScm
  class GitSvnActivity < Activity
    attr_accessor :final_token

    def_delegators :scm, :url

    def commit_count(opts = {})
      cmd = "#{after_revision(opts)} | grep -E -e '^r[0-9]+.*lines$' | wc -l"
      git_svn_log(cmd: cmd, oneline: false).to_i
    end

    def source_scm_commit_count(opts = {})
      source_scm = opts[:source_scm].scm
      options = username_and_password_opts(source_scm)
      svn_log = run("#{accept_ssl_certificate_cmd} svn info #{options} '#{source_scm.url}'")
      svn_log =~ /Revision: ([\d]*)/
      Regexp.last_match(1).to_i - opts[:after].to_i
    end

    def commits(opts = {})
      parsed_commits = []
      open_log_file(opts) do |io|
        parsed_commits = OhlohScm::SvnParser.parse(io)
      end
      parsed_commits
    end

    def commit_tokens(opts = {})
      cmd = "#{after_revision(opts)} | #{extract_revision_number}"
      git_svn_log(cmd: cmd, oneline: false).split.map(&:to_i)
    end

    def each_commit(opts = {})
      commits(opts).each { |commit| yield commit }
    end

    def open_log_file(opts = {})
      cmd = "-v #{after_revision(opts)} | #{string_encoder_path} > #{log_filename}"
      git_svn_log(cmd: cmd, oneline: false)
      File.open(log_filename, 'r') { |io| yield io }
    end

    def log_filename
      File.join('/tmp', url.gsub(/\W/, '') + '.log')
    end

    def after_revision(opts)
      next_token = opts[:after].to_i + 1
      next_head_token = head_token.to_i + 1
      "-r#{next_token}:#{next_head_token}"
    end

    def extract_revision_number
      "grep '^r[0-9].*|' | awk -F'|' '{print $1}' | cut -c 2-"
    end

    def root
      Regexp.last_match(1) if info =~ /^Repository Root: (.+)$/
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
      File.expand_path('../../bin/accept_svn_ssl_certificate', __dir__)
    end

    def username_and_password_opts(source_scm = scm)
      username = source_scm.username.to_s.empty? ? '' : "--username #{source_scm.username}"
      password = source_scm.password.to_s.empty? ? '' : "--password='#{source_scm.password}'"
      "#{username} #{password}"
    end

    def cat_file(commit, diff)
      cat(git_commit(commit), diff.path)
    end

    def cat_file_parent(commit, diff)
      cat("#{git_commit(commit)}^", diff.path)
    end

    def cat(revision, file_path)
      file_path = file_path.to_s
      run("cd #{url} && git show #{revision}:#{file_path.shellescape}").strip
    end

    def git_commit(commit)
      run("cd #{url} && git svn find-rev r#{commit.token}").strip
    end

    def ls(path = nil, revision = final_token || 'HEAD')
      begin
        stdout = run "svn ls --trust-server-cert --non-interactive -r #{revision} "\
          "#{username_and_password_opts} "\
          "'#{uri_encode(File.join(root, scm.branch_name.to_s, path.to_s))}@#{revision}'"
      rescue StandardError
        return nil
      end
      stdout.strip
    end

    private

    def git_svn_log_cmd
      "cd #{url} && git svn log"
    end

    def info(path = nil, revision = final_token || 'HEAD')
      @info ||= {}
      uri = path ? File.join(root, scm.branch_name.to_s, path) : url
      @info[[path, revision]] ||= run 'svn info --trust-server-cert --non-interactive -r '\
        "#{revision} #{username_and_password_opts} '#{uri_encode(uri)}@#{revision}'"
    end

    def uri_encode(uri)
      CGI.escape(uri, /#{URI::UNSAFE}|[\[\]';\? ]/) # Add [ ] ' ; ? and space
    end
  end
end
