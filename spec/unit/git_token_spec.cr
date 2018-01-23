require "../spec_helper"

describe "GitToken" do

  it "no_token_returns_nil" do
    OhlohScm::ScratchDir.new do |dir|
      git = GitAdapter.new(url: dir).normalize
      git.read_token.should be_falsey
      git.init_db
      git.read_token.should be_falsey
    end
  end

  it "write_and_read_token" do
    OhlohScm::ScratchDir.new do |dir|
      git = GitAdapter.new(url: dir).normalize
      git.init_db
      git.write_token("FOO")
      git.read_token.should be_falsey # Token not valid until committed
      git.commit_all(OhlohScm::Commit.new)
      git.read_token.should eq("FOO")
    end
  end

  it "commit_all_includes_write_token" do
    OhlohScm::ScratchDir.new do |dir|
      git = GitAdapter.new(url: dir).normalize
      git.init_db
      c = OhlohScm::Commit.new
      c.token = "BAR"
      git.commit_all(c)
      git.read_token.should eq(c.token)
    end
  end

  it "read_token_encoding" do
    with_git_repository("git_with_invalid_encoding") do |git|
      git.read_token
    end
  end
end
