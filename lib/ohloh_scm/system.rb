# frozen_string_literal: true

require 'logger'
require 'open3'

module OhlohScm
  module System
    protected

    def run(cmd)
      out, err, status = Open3.capture3(cmd)
      raise "#{cmd} failed: #{out}\n#{err}" unless status.success?

      out
    end

    def string_encoder_path
      File.expand_path('../../.bin/string_encoder', __dir__)
    end

    def logger
      self.class.logger
    end

    class << self
      # Use a single logger instance.
      def logger
        @logger ||= Logger.new(STDERR)
      end
    end
  end
end
