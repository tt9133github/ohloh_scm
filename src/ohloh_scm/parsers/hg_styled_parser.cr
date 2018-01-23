module OhlohScm::Parsers
  # This parser processes Mercurial logs which have been generated using a custom style.
  # This custom style provides additional information required by Ohloh.
  class HgStyledParser < Parser
    def self.scm
      "hg"
    end

    # Use when you want to include diffs
    def self.verbose_style_path
      File.expand_path(File.join(File.dirname(__FILE__), "hg_verbose_style"))
    end

    # Use when you do not want to include diffs
    def self.style_path
      File.expand_path(File.join(File.dirname(__FILE__), "hg_style"))
    end

    def self.internal_parse(buffer)
      e = OhlohScm::NullCommit.new
      state = :data

      buffer.each_line do |l|
        next_state = state
        if state == :data
          case l
          when /^changeset:\s+([0-9a-f]+)/
            e = OhlohScm::Commit.new
            e.diffs = Array(Diff).new
            e.token = $1
          when /^user:\s+(.+?)(\s+<(.+)>)?$/
            e.committer_name = $1
            e.committer_email = $3?
          when /^date:\s+(.+)$/
            e.committer_date = Time.epoch($1.sub(/\..+$/, "").to_i)
          when /^__BEGIN_FILES__$/
            next_state = :files
          when /^__BEGIN_COMMENT__$/
            next_state = :long_comment
          when /^__END_COMMIT__$/
            yield e unless e.null?
            e = OhlohScm::NullCommit.new
          end

        elsif state == :files
          if l =~ /^__END_FILES__$/
            next_state = :data
          elsif l =~ /^([MAD]) (.+)$/
            e.diffs << OhlohScm::Diff.new(action: $1, path: $2)
          end

        elsif state == :long_comment
          if l =~ /^__END_COMMENT__$/
            next_state = :data
          else
            e.message = "#{e.message}#{l}"
          end
        end
        state = next_state
      end
    end
  end
end

