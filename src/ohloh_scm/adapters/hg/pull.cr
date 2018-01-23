module OhlohScm::Adapters
  class HgAdapter < AbstractAdapter

    def pull(from)
      raise ArgumentError.new("Cannot pull from #{from.inspect}") unless from.is_a?(HgAdapter)
      logger.info { "Pulling #{from.url}" }

      yield(0,1) # Progress bar callback

      unless self.exist?
        run "mkdir -p '#{self.url}'"
        run "rm -rf '#{self.url}'"
        run "hg clone -U '#{from.url}' '#{self.url}'"
      else
        branch_opts = "-r #{ from.branch_name }" if branch_name
        run "cd '#{self.url}' && hg revert --all && hg pull #{ branch_opts } -u -y '#{from.url}'"
      end

      yield(1,1) # Progress bar callback
    end

  end
end
