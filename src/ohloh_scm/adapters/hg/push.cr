module OhlohScm::Adapters
  class HgAdapter < AbstractAdapter

    def push(to)
      raise ArgumentError.new("Cannot push to #{to.inspect}") unless to.is_a?(HgAdapter)
      logger.info { "Pushing to #{to.url}" }

      yield(0,1) # Progress bar callback

      unless to.exist?
        if to.local?
          # Create a new repo on the same local machine. Just use existing pull code in reverse.
          to.pull(self) { |x, y| yield(x, y) }
        else
          run "ssh #{to.hostname} 'mkdir -p #{to.path}'"
          run "scp -rpqB #{hg_path} #{to.hostname}:#{to.path}"
        end
      else
        run "cd '#{self.url}' && hg push -f -y '#{to.url}'"
      end

      yield(1,1) # Progress bar callback
    end

    def local?
      return true if hostname == System.hostname
      return true if url =~ /^file:\/\//
      return true if url !~ /:/
      false
    end

    def hostname
      $1 if url =~ /^ssh:\/\/([^\/]+)/
    end

    def path
      case url
      when /^file:\/\/(.+)$/
        $1
      when /^ssh:\/\/[^\/]+(\/.+)$/
        $1
      when /^[^:]*$/
        url unless url.empty?
      end
    end

    def hg_path
      path && File.join(path.to_s, ".hg")
    end
  end
end
