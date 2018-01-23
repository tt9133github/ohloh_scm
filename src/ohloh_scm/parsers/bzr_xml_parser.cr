# TODO: Add more specs to cover all tag scenarios.

module OhlohScm::Parsers
  class BazaarListener
    @action : StringOrNil
    @before_path : StringOrNil
    @cdata : StringOrNil

    def initialize
      @merge_commit = Array(Commit).new
      @state = :none
      @authors = [] of Hash(Symbol, String | Nil)
      @text = ""
      @commit = Commit.new
      @diffs = Array(Diff).new
    end

    def tag_start(name, attrs)
      case name
      when "log"
        @commit = Commit.new
      when "affected-files"
        @diffs = Array(Diff).new
      when "added", "modified", "removed", "renamed"
        @action = name
        @state = :collect_files
      when "file"
        @before_path = attrs["oldpath"]?
      when "merge"
        # This is a merge commit, save it and pop it after all branch commits
        @merge_commit.push(@commit)
      when "authors"
        @state = :collect_authors
        @authors = [] of Hash(Symbol, String | Nil)
      end
    end

    def tag_end(name)
      case name
      when "log"
        yield @commit
      when "revisionid"
        @commit.token = @text
      when "message"
        @commit.message = @cdata
      when "committer"
        committer = BzrXmlParser.capture_name(@text)
        @commit.committer_name = committer[0]
        @commit.committer_email = committer[1]
      when "author"
        author = BzrXmlParser.capture_name(@text)
        @authors << {:author_name => author[0], :author_email => author[1]}
      when "timestamp"
        @commit.committer_date = Time.parse(@text, "%a %F %T %z")
      when "file"
        if @state == :collect_files
          @diffs.concat(parse_diff(@action, @text, @before_path))
        end
      when "added", "modified", "removed", "renamed"
        @state = :none
      when "affected-files"
        @commit.diffs = remove_dupes(@diffs)
      when "merge"
        @commit = @merge_commit.pop
      when "authors"
        @commit.author_name = @authors[0][:author_name]
        @commit.author_email = @authors[0][:author_email]
        @authors.clear
      end
    end

    def cdata(data)
      @cdata = data
    end

    def text(text)
      @text = text
    end

    # Parse one single diff
    private def parse_diff(action, path, before_path)
      diffs = Array(Diff).new
      case action
        # A rename action requires two diffs: one to remove the old filename,
        # another to add the new filename.
        #
        # Note that is possible to be renamed to the empty string!
        # This happens when a subdirectory is moved to become the root.
      when "renamed"
        diffs = [ Diff.new(action: "D", path: before_path),
                  Diff.new(action: "A", path: path || "")]
      when "added"
        diffs = [Diff.new(action: "A", path: path)]
      when "modified"
        diffs = [Diff.new(action: "M", path: path)]
      when "removed"
        diffs = [Diff.new(action: "D", path: path)]
      end
      diffs.each do |d|
        d.path = strip_trailing_asterisk(d.path)
      end
      diffs
    end

    private def strip_trailing_asterisk(path)
      return unless path
      path[-1..-1] == "*" ? path[0..-2] : path
    end

    private def remove_dupes(diffs)
      BzrXmlParser.remove_dupes(diffs)
    end
  end

  class BzrXmlParser < Parser
    NAME_REGEX = /^(.+?)(\s+<(.+)>\s*)?$/
    def self.internal_parse(buffer)
      buffer = IO::Memory.new("<?xml?>") if buffer.is_a?(IO) && buffer.size < 2
      XmlStreamer.parse(buffer, BazaarListener.new) { |c| yield c }
    rescue IO::EOFError
    end

    def self.scm
      "bzr"
    end

    def self.remove_dupes(diffs)
      # Bazaar may report that a file was added and modified in a single commit.
      # Reduce these cases to a single "A" action.
      diffs.reject! do |d|
        d.action == "M" && diffs.select { |x| x.path == d.path && x.action == "A" }.any?
      end

      # Bazaar may report that a file was both deleted and added in a single commit.
      # Reduce these cases to a single "M" action.
      diffs.map do |diff|
        diff.action = "M" if diffs.select { |x| x.path == diff.path }.size > 1
        diff
      end.uniq { |diff| diff.path || diff.action }
    end

    # Bazaar expects committer/author to be specified in this format
    # Name <email>, or John Doe <jdoe@example.com>
    # However, we find many variations in the real world including
    # ones where only email is specified as name.
    def self.capture_name(text)
      parts = text.match(NAME_REGEX).try(&.to_a) || Array(Nil).new
      name = parts[1]? || parts[0]
      email = parts[3]
      [name, email]
    end
  end
end
