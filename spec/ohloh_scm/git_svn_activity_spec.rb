require 'spec_helper'

describe 'GitSvnActivity' do
  describe 'cat' do
    let(:commit_1) { OhlohScm::Commit.new(token: 1) }
    let(:hello_diff) { OhlohScm::Diff.new(path: 'helloworld.c') }

    it 'cat_file' do
      with_git_svn_repository('git_svn') do |git_svn|
        expected = <<-EXPECTED.gsub(/^\s+/, '')
          /* Hello, World! */
          #include <stdio.h>
          main()
          {
            printf("Hello, World!\\n");
          }
        EXPECTED

        git_svn.activity.cat_file(commit_1, hello_diff)
               .delete("\t").strip.must_equal expected.strip
      end
    end

    it 'cat_file_with_non_existent_token' do
      with_git_svn_repository('git_svn') do |git_svn|
        assert git_svn.activity.cat_file(OhlohScm::Commit.new(token: 999), hello_diff)
      end
    end

    it 'cat_file_with_invalid_filename' do
      with_git_svn_repository('git_svn') do |git_svn|
        -> { git_svn.activity.cat_file(commit_1, OhlohScm::Diff.new(path: 'invalid')) }.must_raise(RuntimeError)
      end
    end

    it 'cat_file_parent' do
      with_git_svn_repository('git_svn') do |git_svn|
        expected = <<-EXPECTED.gsub(/^\s+/, '')
          /* Hello, World! */
          #include <stdio.h>
          main()
          {
            printf("Hello, World!\\n");
          }
        EXPECTED

        commit = OhlohScm::Commit.new(token: 2)
        git_svn.activity.cat_file_parent(commit, hello_diff).delete("\t").must_equal expected.strip
      end
    end

    it 'cat_file_parent_with_first_token' do
      with_git_svn_repository('git_svn') do |git_svn|
        assert git_svn.activity.cat_file(commit_1, hello_diff)
      end
    end
  end
end
