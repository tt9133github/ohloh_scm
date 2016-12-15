require 'logger'

module OhlohScm::Adapters
  module System
    def self.included(base)
      base.extend ClassMethods
    end

    def logger
      self.class.logger
    end

    def run(cmd)
      AbstractAdapter::run(cmd)
    end

    def run_with_err(cmd)
      AbstractAdapter::run_with_err(cmd)
    end 

    module ClassMethods
      def logger
        @@logger ||= Logger.new(STDERR)
      end

      def logger=(val)
        @@logger = val
      end

      # Custom implementation of shell execution, does not block when the "pipe is full."
      # Raises an exception if the shell returns non-zero exit code.
      def run(cmd)
        logger.debug { cmd }
        status, out, err = Shellout.execute(cmd)
        raise RuntimeError.new("#{cmd} failed: #{out}\n#{err}") if status.exitstatus != 0
        out
      end

      # As above, but does not raise an exception when an error occurs.
      # Returns three values: stdout, stderr, and process exit code
      def run_with_err(cmd)
        logger.debug { cmd }
        status, out, err = Shellout.new.run(cmd)
        [out, err, status]
      end
    end
  end
end
