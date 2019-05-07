# frozen_string_literal: true

module OhlohScm
  class GitSvnScm < Scm
    def initialize(base:, url:, branch_name:, username:, password:)
      super
      @branch_name = branch_name || :master
    end

    def pull(source_scm)
      @source_scm = source_scm.scm
      convert_to_git
    end

    def normalize
      super
      url = path_to_file_url(self.url)
      @url = force_https_if_sourceforge(url)
      if branch_name
        clean_branch_name
      else
        @branch_name = recalc_branch_name
      end
      self
    end

    # From the given URL, determine which part of it is the root and
    # which part of it is the branch_name. The current branch_name is overwritten.
    def recalc_branch_name
      begin
        @branch_name = url ? url[activity.root.length..-1] : branch_name
      rescue RuntimeError => e
        pattern = /(svn:*is not a working copy|Unable to open an ra_local session to URL)/
        @branch_name = '' if e.message =~ pattern # we have a file system
      end
      clean_branch_name
      branch_name
    end

    private

    def clean_branch_name
      return unless branch_name

      @branch_name.chop! if branch_name.to_s.end_with?('/')
    end

    def force_https_if_sourceforge(url)
      return url unless url =~ /http(:\/\/.*svn\.(sourceforge|code\.sf)\.net.*)/

      # SourceForge requires https for svnsync
      "https#{Regexp.last_match(1)}"
    end

    # If the URL is a simple directory path, make sure it is prefixed by file://
    def path_to_file_url(path)
      return nil if path.empty?

      /:\/\//.match?(url) ? url : 'file://' + File.expand_path(path)
    end

    def convert_to_git
      if FileTest.exist?(git_path)
        accept_certificate_if_prompted
        fetch
      else
        clone
      end

      clean_up_disk
    end

    def git_path
      File.join(url, '/.git')
    end

    def clone
      prepare_dest_dir
      accept_certificate_if_prompted

      cmd = "#{password_prompt} git svn clone --quiet #{username_opts}"\
              " '#{@source_scm.url}' '#{url}'"
      run(cmd)
    end

    def accept_certificate_if_prompted
      # git svn does not support non iteractive and serv-certificate options
      # Permanently accept svn certificate when it prompts
      opts = username_and_password_opts
      run "#{accept_ssl_certificate_cmd} svn info #{opts} '#{@source_scm.url}'"
    end

    def username_and_password_opts
      username = username.to_s.empty? ? '' : "--username #{@source_scm.username}"
      password = password.to_s.empty? ? '' : "--password='#{@source_scm.password}'"
      "#{username} #{password}"
    end

    def accept_ssl_certificate_cmd
      File.expand_path('../../bin/accept_svn_ssl_certificate', __dir__)
    end

    def password_prompt
      password.to_s.empty? ? '' : "echo #{password} |"
    end

    def username_opts
      username.to_s.empty? ? '' : "--username #{username}"
    end

    def prepare_dest_dir
      FileUtils.mkdir_p(url)
      FileUtils.rm_rf(url)
    end

    def fetch
      cmd = "cd #{url} && git svn fetch"
      run(cmd)
    end

    def clean_up_disk
      return unless  File.exist?(url)

      run "cd #{url} && find . -maxdepth 1 -not -name .git -not -name . -print0"\
            ' | xargs -0 rm -rf --'
    end
  end
end
