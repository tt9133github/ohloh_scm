require "../test_helper"

describe "GitCommitAll" do

  it "commit_all" do
    OhlohScm::ScratchDir.new do |dir|
      git = GitAdapter.new(:url => dir).normalize

      git.init_db
      git.anything_to_commit?.should be_falsey

      File.open(File.join(dir, "README"), "w") {}
      git.anything_to_commit?.should be_truthy

      c = OhlohScm::Commit.new
      c.author_name = "John Q. Developer"
      c.message = "Initial checkin."
      git.commit_all(c)
      git.anything_to_commit?.should be_falsey

      git.commits.size.should eq(1)

      git.commits.first.author_name.should eq(c.author_name)
      # Depending on version of Git used, we may or may not have trailing \n.
      # We don"t really care, so just compare the stripped versions.
      git.commits.first.message.strip.should eq(c.message.strip)

      git.commits.first.diffs.map { |d| d.path }.sort.should eq([".gitignore", "README"])
    end
  end

end
