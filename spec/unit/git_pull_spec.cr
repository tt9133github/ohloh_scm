require "../test_helper"

describe "GitPull" do

  it "basic_pull" do
    with_git_repository("git") do |src|
      OhlohScm::ScratchDir.new do |dest_dir|

        dest = GitAdapter.new(:url => dest_dir).normalize
        dest.exist?.should be_falsey

        dest.pull(src)
        dest.exist?.should be_truthy

        dest.log.should eq(src.log)
      end
    end
  end

  it "basic_pull_with_exception" do
    with_svn_repository("svn_empty") do |src|
      OhlohScm::ScratchDir.new do |dest_dir|
        dest = GitAdapter.new(:url => dest_dir).normalize
        dest.exist?.should be_falsey
        err = expect_raises(RuntimeError) { dest.pull(src) }
        err.message.should match(/Empty repository/)
      end
    end
  end
end
