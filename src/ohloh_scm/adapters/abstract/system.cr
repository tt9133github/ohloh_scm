require "logger"

module OhlohScm::Adapters
  class AbstractAdapter
    def self.logger
      @@logger ||= Logger.new(STDERR)
    end

    def self.logger=(val)
      @@logger = val
    end

    def logger
      self.class.logger
    end

    # Custom implementation of shell execution, does not block when the "pipe is full."
    # Raises an exception if the shell returns non-zero exit code.
    def self.run(cmd)
      logger.debug { cmd }
      status, output, err = Shellout.execute(cmd)
      raise Exception.new("#{cmd} failed: #{output}\n#{err}") unless status.success?
      output
    end

    def run(cmd)
      AbstractAdapter.run(cmd)
    end

    # As above, but does not raise an exception when an error occurs.
    # Returns three values: stdout, stderr, and process exit code
    def self.run_with_err(cmd)
      logger.debug { cmd }
      status, output, err = Shellout.execute(cmd)
      {output, err, status.exit_code}
    end

    def run_with_err(cmd)
      AbstractAdapter.run_with_err(cmd)
    end
  end
end
