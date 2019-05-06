# frozen_string_literal: true

module OhlohScm
  class GitSvnStatus < Status
    def url_regex
      /^(file|http|https|svn):\/\/(\/)?[A-Za-z0-9_\-\.]+(:\d+)?(\/[A-Za-z0-9_@\-\.\/\+%^~ ]*)?$/
    end

    def public_url_regex
      /^(http|https|svn):\/\/[A-Za-z0-9_\-\.]+(:\d+)?(\/[A-Za-z0-9_\-\.\/\+%^~ ]*)?$/
    end

    # Subversion usernames have been relaxed from the abstract rules. We allow email names as usernames.
    def validate_username
      username = scm.username
      return nil unless username
      return nil if username.empty?
      return [:username, 'The username must not be longer than 32 characters.'] unless username.length <= 32
      return [:username, 'The username contains illegal characters.'] unless username =~ /^\w[\w@\.\+\-]*$/
    end

    def validate_server_connection
      return unless valid?

      begin
        @errors ||= []
        if activity.head_token.nil?
          msg = "The server did not respond to a 'svn info' command. Is the URL correct?"
          @errors << [:failed, msg]
        elsif scm.url[0..activity.root.length - 1] != activity.root
          msg = "The URL did not match the Subversion root #{activity.root}. Is the URL correct?"
          @errors << [:failed, msg]
        elsif scm.recalc_branch_name && activity.ls.nil?
          msg = "The server did not respond to a 'svn ls' command. Is the URL correct?"
          @errors << [:failed, msg]
        end
      rescue StandardError
        logger.error { $ERROR_INFO.inspect }
        msg = 'An error occured connecting to the server. Check the URL, username, and password.'
        @errors << [:failed, msg]
      end
    end

    def guess_forge
      u = scm.url =~ /:\/\/(.*\.?svn\.)?([^\/^:]+)(:\d+)?(\/|$)/ ? Regexp.last_match(2) : nil
      case u
      when /(googlecode\.com$)/, /(tigris\.org$)/, /(sunsource\.net$)/, /(java\.net$)/,
        /(openoffice\.org$)/, /(netbeans\.org$)/, /(dev2dev\.bea\.com$)/, /(rubyforge\.org$)/
        Regexp.last_match(1)
      else
        u
      end
    end
  end
end
