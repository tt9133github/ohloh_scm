# frozen_string_literal: true

module OhlohScm
  module Git
    class CommitConverter
      attr_reader :commit

      def initialize(rugged_commit)
        @commit = OhlohScm::Commit.new
        @rugged_commit = rugged_commit

        commit.token = @rugged_commit.oid
        commit.message = @rugged_commit.message

        assign_author_data
        assign_committer_data
        assign_diffs
      end

      private

      def assign_diffs
        commit.diffs = []
        rugged_diffs = @rugged_commit.parents[0].diff(@rugged_commit)
        rugged_diffs.each do |rugged_diff|
          delta = rugged_diff.delta
          commit.diffs << OhlohScm::Diff.new(action: delta.status, path: delta.old_file[:path],
                                             sha1: delta.old_file[:oid], parent_sha1: nil)
        end
      end

      def assign_author_data
        @commit.author_name = @rugged_commit.author[:name]
        @commit.author_email = @rugged_commit.author[:email]
        @commit.author_date = @rugged_commit.author[:time]
      end

      def assign_committer_data
        @commit.committer_name = @rugged_commit.committer[:name]
        @commit.committer_email = @rugged_commit.committer[:email]
        @commit.committer_date = @rugged_commit.committer[:time]
      end
    end
  end
end
