module OhlohScm
  class GitSvnScm < Scm
    def initialize(base:, url:, branch_name: nil)
      super
      @branch_name = branch_name || :master
    end

    def pull
      convert_to_git
    end

    private

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

      cmd = "#{password_prompt} git svn clone --quiet #{username_opts} '#{url}' '#{base.dir}'"
      run(cmd)
    end

    def accept_certificate_if_prompted
      # git svn does not support non iteractive and serv-certificate options
      # Permanently accept svn certificate when it prompts
      opts = username_and_password_opts
      run "#{accept_ssl_certificate_cmd} svn info #{opts} '#{url}'"
    end

    def password_prompt
      password.to_s.empty? ? '' : "echo #{ password } |"
    end

    def username_opts
      username.to_s.empty? ? '' : "--username #{ username }"
    end

    def prepare_dest_dir
      FileUtils.mkdir_p(url)
      FileUtils.rmdir(url)
    end

    def fetch
      cmd = "cd #{ base.dir } && git svn fetch"
      run(cmd)
    end

    def clean_up_disk
      if FileTest.exist?(url)
        run("cd #{ base.dir } && find . -maxdepth 1 -not -name .git -not -name . -print0 | xargs -0 rm -rf --")
  end
end
