require "../test_helper"

describe "GitPull" do

  it "basic_pull" do
    with_git_repository("git") do |src|
      OhlohScm::ScratchDir.new do |dest_dir|

        dest = GitAdapter.new(:url => dest_dir).normalize
        assert !dest.exist?

        dest.pull(src)
        assert dest.exist?

        assert_equal src.log, dest.log
      end
    end
  end

  it "basic_pull_with_exception" do
    with_svn_repository("svn_empty") do |src|
      OhlohScm::ScratchDir.new do |dest_dir|
        dest = GitAdapter.new(:url => dest_dir).normalize
        assert !dest.exist?
        err = assert_raises(RuntimeError) { dest.pull(src) }
        assert_match /Empty repository/, err.message
      end
    end
  end
end
