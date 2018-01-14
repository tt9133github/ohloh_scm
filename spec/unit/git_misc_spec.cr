require "../spec_helper"

describe "GitMisc" do

  it "export" do
    with_git_repository("git") do |git|
      OhlohScm::ScratchDir.new do |dir|
        git.export(dir)
        Dir.entries(dir).sort.should eq([".","..",".gitignore","COPYING","README","helloworld.c","makefile","ohloh_token"])
      end
    end
  end

  it "branches" do
    with_git_repository("git") do |git|
      git.branches.should eq(["develop", "master"])
      git.has_branch?("master").should be_truthy
    end
  end

  it "ls_tree" do
    with_git_repository("git") do |git|
      git.ls_tree(git.head_token).sort.should eq([".gitignore","COPYING","README","helloworld.c","makefile","ohloh_token"])
    end
  end

  it "is_merge_commit" do
    with_git_repository("git_walk") do |git|
      git.is_merge_commit?(OhlohScm::Commit.new({:token => "f264fb40c340a415b305ac1f0b8f12502aa2788f"})).should be_truthy
      git.is_merge_commit?(OhlohScm::Commit.new({:token => "d067161caae2eeedbd74976aeff5c4d8f1ccc946"})).should be_falsey
    end
  end

  it "branches_encoding" do
    with_git_repository("git_with_invalid_encoding") do |git|
      git.branches.all? { |branch| branch.valid_encoding? }.should eq(true)
    end
  end

  # `git ls-tree` returns filenames in valid utf8 regardless of their original form.
  it "ls_tree_encoding" do
    with_git_repository("git_with_invalid_encoding") do |git|
      git.ls_tree.all? { |filename| filename.valid_encoding? }.should eq(true)
    end
  end

  it "fixture_repo_has_dereferenced_tags" do
    with_git_repository("git") do |git|
      tag_shas = git.run("cd #{git.url} && git tag --format='%(objectname)' | sed 's/refs\\/tags\\///'").split(/\n/)
      tag_shas.any? { |sha| not git.commit_tokens.include?(sha) }.should eq(true)
    end
  end

  it "tags" do
    with_git_repository("git") do |git|
      git.tags.should eq([["v1.0.0", "b6e9220c3cabe53a4ed7f32952aeaeb8a822603d", Time.parse("2016-07-31T07:58:30+05:30")],
                          ["v1.1.0-lw", "2e9366dd7a786fdb35f211fff1c8ea05c51968b1", Time.parse("2006-06-11T11:34:17-07:00")],
                          ["v2.1.0", "1df547800dcd168e589bb9b26b4039bff3a7f7e4", Time.parse("2006-07-14T16:07:15-07:00")]])
    end
  end

  it "tags_reference_valid_commits" do
    with_git_repository("git") do |git|
      tag_shas = git.tags.map { |list| list[1] }
      tag_shas.all? { |sha| git.commit_tokens.include?(sha) }.should eq(true)
    end
  end

  it "tags_with_non_tagged_repository" do
    with_git_repository("git_walk") do |git|
      [].should eq(git.tags)
    end
  end
end
