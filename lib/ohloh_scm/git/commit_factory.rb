# frozen_string_literal: true

module OhlohScm
  module Git
    class CommitFactory
      def initialize(url, branch)
        @url = url
        @branch = branch
      end

      def commits
        rugged_commits = repository.walk("refs/heads/#{branch || :master}")
        rugged_commits.map { |cm| CommitConverter.new(cm).commit }
      end

      private

      def repository
        @repository ||= Rugged::Repository.new(@url)
      end
    end
  end
end
