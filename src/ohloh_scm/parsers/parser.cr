module OhlohScm::Parsers
  class Parser
    def self.parse(buffer, branch_name = nil)
      io = build_io(buffer)
      commits = [] of Commit
      if branch_name
        internal_parse(io, branch_name: branch_name) { |commit| commits << commit } # Used by CvsParser.
      else
        internal_parse(io) { |commit| commits << commit }
      end
      commits
    end

    def self.parse(buffer, &block)
      io = build_io(buffer)
      internal_parse(io) { |commit| yield commit if commit }
    end

    def self.internal_parse(_io)
      raise Exception.new("Abstract method not implemented")
    end

    def self.internal_parse(_io, branch_name = "", &block)
      raise Exception.new("Abstract method not implemented")
    end

    def self.build_io(buffer)
      buffer.is_a?(String) ? IO::Memory.new(string: buffer) : buffer
    end
  end
end
