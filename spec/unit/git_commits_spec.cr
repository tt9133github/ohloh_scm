require "../test_helper"

describe "GitCommits" do

  it "commit_count" do
    with_git_repository("git") do |git|
      git.commit_count.should eq(4)
      git.commit_count(:after => "b6e9220c3cabe53a4ed7f32952aeaeb8a822603d").should eq(2)
      git.commit_count(:after => "1df547800dcd168e589bb9b26b4039bff3a7f7e4").should eq(0)
    end
  end

  it "commit_tokens" do
    with_git_repository("git") do |git|
      git.commit_tokens.should eq(["089c527c61235bd0793c49109b5bd34d439848c6",
                                  "b6e9220c3cabe53a4ed7f32952aeaeb8a822603d",
                                  "2e9366dd7a786fdb35f211fff1c8ea05c51968b1",
                                  "1df547800dcd168e589bb9b26b4039bff3a7f7e4"])

      git.commit_tokens(:after => "2e9366dd7a786fdb35f211fff1c8ea05c51968b1").should eq(
        ["1df547800dcd168e589bb9b26b4039bff3a7f7e4"])

      git.commit_tokens(:after => "1df547800dcd168e589bb9b26b4039bff3a7f7e4").should eq([])
    end
  end

  it "commits" do
    with_git_repository("git") do |git|
      git.commits.map { |c| c.token }.should eq(["089c527c61235bd0793c49109b5bd34d439848c6",
                                                 "b6e9220c3cabe53a4ed7f32952aeaeb8a822603d",
                                                 "2e9366dd7a786fdb35f211fff1c8ea05c51968b1",
                                                 "1df547800dcd168e589bb9b26b4039bff3a7f7e4"])

      git.commits(:after => "2e9366dd7a786fdb35f211fff1c8ea05c51968b1").map { |c| c.token }.should eq(
        ["1df547800dcd168e589bb9b26b4039bff3a7f7e4"])

      git.commits(:after => "1df547800dcd168e589bb9b26b4039bff3a7f7e4").should eq([])
    end
  end

  it "commits_with_branch" do
    with_git_repository("git", "develop") do |git|
      git.commits.map(&:token).should eq(["089c527c61235bd0793c49109b5bd34d439848c6",
                                          "b6e9220c3cabe53a4ed7f32952aeaeb8a822603d",
                                          "2e9366dd7a786fdb35f211fff1c8ea05c51968b1",
                                          "b4046b9a80fead62fa949232f2b87b0cb78fffcc"])

      git.commits(:after => "2e9366dd7a786fdb35f211fff1c8ea05c51968b1").map(&:token).should eq(
        ["b4046b9a80fead62fa949232f2b87b0cb78fffcc"])

      git.commits(:after => "b4046b9a80fead62fa949232f2b87b0cb78fffcc").should eq([])
    end
  end

  it "trunk_only_commit_count" do
    with_git_repository("git_dupe_delete") do |git|
      git.commit_count(:trunk_only => false).should eq(4)
      git.commit_count(:trunk_only => true).should eq(3)
    end
  end

  it "trunk_only_commit_tokens" do
    with_git_repository("git_dupe_delete") do |git|
      git.commit_tokens(:trunk_only => false).should eq(["a0a2b8623941562031a7d7f95d984feb4a2d719c",
                                                         "ad6bb43112706c462e53a9a8a8cd3b05f8e9260f",
                                                         "6126337d2497806528fd8657181d5d4afadd72a4", # On branch
                                                         "41c4b1044ebffc968d363e5f5e883134e624f846"])

      git.commit_tokens(:trunk_only => true).should eq(["a0a2b8623941562031a7d7f95d984feb4a2d719c",
                                                        "ad6bb43112706c462e53a9a8a8cd3b05f8e9260f",
                                                        # "6126337d2497806528fd8657181d5d4afadd72a4", # On branch
                                                        "41c4b1044ebffc968d363e5f5e883134e624f846"])

    end
  end

  it "trunk_only_commit_tokens_using_after" do
    with_git_repository("git_dupe_delete") do |git|
      git.commit_tokens(:after => "a0a2b8623941562031a7d7f95d984feb4a2d719c", :trunk_only => true).should eq(
        ["ad6bb43112706c462e53a9a8a8cd3b05f8e9260f", "41c4b1044ebffc968d363e5f5e883134e624f846"])

      # All trunk commit_tokens, with :after == HEAD
      git.commit_tokens(:after => "41c4b1044ebffc968d363e5f5e883134e624f846", :trunk_only => true).should eq([])
    end
  end

  it "trunk_only_commits" do
    with_git_repository("git_dupe_delete") do |git|
      git.commits(:trunk_only => true).map { |c| c.token }.should eq(["a0a2b8623941562031a7d7f95d984feb4a2d719c",
                                                                     "ad6bb43112706c462e53a9a8a8cd3b05f8e9260f",
                                                                     # The following commit is on a branch and should be excluded
                                                                     # "6126337d2497806528fd8657181d5d4afadd72a4",
                                                                     "41c4b1044ebffc968d363e5f5e883134e624f846"])
    end
  end

  it "trunk_only_commits_using_after" do
    with_git_repository("git_dupe_delete") do |git|
      git.commits({after: "a0a2b8623941562031a7d7f95d984feb4a2d719c", trunk_only: true}).map { |c| c.token }.should eq(
        ["ad6bb43112706c462e53a9a8a8cd3b05f8e9260f", "41c4b1044ebffc968d363e5f5e883134e624f846"])

      git.commit_tokens(:after => "41c4b1044ebffc968d363e5f5e883134e624f846", :trunk_only => true).should eq([])
    end
  end

  # In rare cases, a merge commit"s resulting tree is identical to its first parent"s tree.
  # I believe this is a result of developer trickery, and not a common situation.
  #
  # When this happens, `git whatchanged` will omit the changes relative to the first parent,
  # and instead output only the changes relative to the second parent.
  #
  # Our commit parser became confused by this, assuming that these changes relative to the
  # second parent were in fact the missing changes relative to the first.
  #
  # This is bug OTWO-623. This test confirms the fix.
  it "verbose_commit_with_null_merge" do
    with_git_repository("git_with_null_merge") do |git|
      c = git.verbose_commit("d3bd0bedbf4b197b2c4eb827e1ec4c35b834482f")
      # This commit"s tree is identical to its parent"s. Thus it should contain no diffs.
      c.diffs.should eq([])
    end
  end

  it "each_commit_with_null_merge" do
    with_git_repository("git_with_null_merge") do |git|
      git.each_commit do |c|
        c.diffs if c.token == "d3bd0bedbf4b197b2c4eb827e1ec4c35b834482f".should eq([])
      end
    end
  end

  it "log_encoding" do
    with_git_repository("git_with_invalid_encoding") do |git|
      git.log.valid_encoding?.should eq(true)
    end
  end

  it "verbose_commits_valid_encoding" do
    with_git_repository("git_with_invalid_encoding") do |git|
      git.verbose_commit("8d03f4ea64fcd10966fb3773a212b141ada619e1").message.valid_encoding?.should be_true
    end
  end

  it "open_log_file_encoding" do
    with_git_repository("git_with_invalid_encoding") do |git|
      git.open_log_file do |io|
        io.read.valid_encoding?.should eq(true)
      end
    end
  end
end
