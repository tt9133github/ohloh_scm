module OhlohScm::Adapters
  class BzrAdapter < AbstractAdapter

    def pull(from)
      raise ArgumentError.new("Cannot pull from #{from.inspect}") unless from.is_a?(BzrAdapter)
      logger.info { "Pulling #{from.url}" }

      yield(0,1)

      unless self.exist?
        run "mkdir -p '#{self.url}'"
        run "rm -rf '#{self.url}'"
        run "bzr branch '#{from.url}' '#{self.url}'"
      else
        run "cd '#{self.url}' && bzr revert && bzr pull --overwrite '#{from.url}'"
      end

      yield(1,1)
    end

  end
end
