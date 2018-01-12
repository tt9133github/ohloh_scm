require "../test_helper"

describe "GitToken" do

  it "no_token_returns_nil" do
    OhlohScm::ScratchDir.new do |dir|
      git = GitAdapter.new(:url => dir).normalize
      assert !git.read_token
      git.init_db
      assert !git.read_token
    end
  end

  it "write_and_read_token" do
    OhlohScm::ScratchDir.new do |dir|
      git = GitAdapter.new(:url => dir).normalize
      git.init_db
      git.write_token("FOO")
      assert !git.read_token # Token not valid until committed
      git.commit_all(OhlohScm::Commit.new)
      assert_equal "FOO", git.read_token
    end
  end

  it "commit_all_includes_write_token" do
    OhlohScm::ScratchDir.new do |dir|
      git = GitAdapter.new(:url => dir).normalize
      git.init_db
      c = OhlohScm::Commit.new
      c.token = "BAR"
      git.commit_all(c)
      assert_equal c.token, git.read_token
    end
  end

  it "read_token_encoding" do
    with_git_repository("git_with_invalid_encoding") do |git|
      assert_nothing_raised do
        git.read_token
      end
    end
  end
end
