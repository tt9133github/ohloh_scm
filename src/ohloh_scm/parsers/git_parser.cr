module OhlohScm::Parsers
  class GitParser < Parser
    def self.scm
      "git"
    end

    ANONYMOUS = "(no author)"

    def self.internal_parse(io)
      e = OhlohScm::NullCommit.new
      state = :key_values

      io.each_line do |line|
        line = line.chomp

        # Kind of a hack: the diffs section is not always present.
        # Also, we don't know when the next commit is going to begin,
        # so we may need to make an unexpected state change.
        if line =~ /^commit ([a-z0-9]{40,40})$/
          state = :key_values
        elsif state == :message && line =~ /^[ADM]\s+(.+)$/
          state = :diffs
        end

        if state == :key_values
          case line
          when /^commit ([a-z0-9]{40,40})$/
            sha1 = $1
            yield e unless e.null?
            e = OhlohScm::Commit.new
            e.diffs = Array(Diff).new
            e.token = sha1
            e.author_name = ANONYMOUS
          when /^Author: (.+) <(.*)>$/
            # In the rare case that the Git repository does not contain any names (see OpenEmbedded for example)
            # we use the email instead.
            e.author_name = $1 || $2
            e.author_email = $2
          when /^Date: (.*)$/
            e.author_date = Time.parse($1.strip, "%a, %d %b %Y %T %z").to_utc # Note strongly: MUST be RFC2822 format to parse properly
            state = :message
          end

        elsif state == :message
          case line
          when /    (.*)/
            if e.message
              e.message = "#{e.message}\n#{$1}"
            else
              e.message = $1
            end
          end

        elsif state == :diffs
          if line =~ /^([ADM])\t(.+)$/
            e.diffs << OhlohScm::Diff.new(action: $1, path: $2)
          end

        else
          raise Exception.new("Unknown parser state #{state.to_s}")
        end
      end

      yield e unless e.null?
    end
  end
end
