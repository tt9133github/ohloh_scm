module OhlohScm::Parsers
  class SubversionListener
    def initialize
      @commit = Commit.new
      @text = ""
      @diff = Diff.new
    end

    def tag_start(name, attrs)
      case name
      when "logentry"
        @commit = Commit.new
        @commit.token = attrs["revision"]?
      when "path"
        @diff = Diff.new(action: attrs["action"]?,
                         from_path: attrs["copyfrom-path"]?,
                         from_revision: (attrs["copyfrom-rev"]? && attrs["copyfrom-rev"].to_i).as(IntOrNil))
      end
    end

    def tag_end(name)
      case name
      when "logentry"
        yield @commit
      when "author"
        @commit.committer_name = @text
      when "date"
        # NOTE: In the ruby ohloh_scm, we used to round the time so that 42.9 secs became 43 secs. We don't do that in Crystal.
        @commit.committer_date = Time.parse(@text, "%FT%T.%z", Time::Kind::Utc).to_utc
      when "path"
        @diff.path = @text
        @commit.diffs << @diff
      when "msg"
        @commit.message = @text
      end
    end

    def text(text)
      @text = text
    end
  end

  class SvnXmlParser < Parser
    def self.internal_parse(buffer)
      buffer = IO::Memory.new("<?xml?>") if buffer.is_a?(IO) && buffer.size < 2
      XmlStreamer.parse(buffer, SubversionListener.new) { |c| yield c }
    rescue IO::EOFError
    end

    def self.scm
      "svn"
    end
  end
end
