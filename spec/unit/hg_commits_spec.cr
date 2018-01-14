require "../spec_helper"

describe "HgCommits" do

  it "commit_count" do
    with_hg_repository("hg") do |hg|
      hg.commit_count.should eq(5)
      hg.commit_count({:after => "b14fa4692f949940bd1e28da6fb4617de2615484"}).should eq(3)
      hg.commit_count({:after => "655f04cf6ad708ab58c7b941672dce09dd369a18"}).should eq(0)
    end
  end

  it "commit_count_with_empty_branch" do
          with_hg_repository("hg", "") do |hg|
          hg.branch_name.should eq(nil)
          hg.commit_count.should eq(5)
          hg.commit_count({:after => "b14fa4692f949940bd1e28da6fb4617de2615484"}).should eq(3)
          hg.commit_count({:after => "655f04cf6ad708ab58c7b941672dce09dd369a18"}).should eq(0)
        end
    end


  it "commit_tokens" do
    with_hg_repository("hg") do |hg|
      hg.commit_tokens.should eq(["01101d8ef3cea7da9ac6e9a226d645f4418f05c9",
                                  "b14fa4692f949940bd1e28da6fb4617de2615484",
                                  "468336c6671cbc58237a259d1b7326866afc2817",
                                  "75532c1e1f1de55c2271f6fd29d98efbe35397c4",
                                  "655f04cf6ad708ab58c7b941672dce09dd369a18"])

      hg.commit_tokens({:after => "75532c1e1f1de55c2271f6fd29d98efbe35397c4"}).should eq(
        ["655f04cf6ad708ab58c7b941672dce09dd369a18"])

      hg.commit_tokens({:after => "655f04cf6ad708ab58c7b941672dce09dd369a18"}).should eq(Array(Nil).new)
    end
  end

  it "commits" do
    with_hg_repository("hg") do |hg|
      hg.commits.map { |c| c.token }.should eq(["01101d8ef3cea7da9ac6e9a226d645f4418f05c9",
                                                "b14fa4692f949940bd1e28da6fb4617de2615484",
                                                "468336c6671cbc58237a259d1b7326866afc2817",
                                                "75532c1e1f1de55c2271f6fd29d98efbe35397c4",
                                                "655f04cf6ad708ab58c7b941672dce09dd369a18"])

      hg.commits({:after => "75532c1e1f1de55c2271f6fd29d98efbe35397c4"}).map { |c| c.token }.should eq(
        ["655f04cf6ad708ab58c7b941672dce09dd369a18"])

      # Check that the diffs are not populated
      hg.commits({:after => "75532c1e1f1de55c2271f6fd29d98efbe35397c4"}).first.diffs.should eq(Array(Nil).new)

      hg.commits({:after => "655f04cf6ad708ab58c7b941672dce09dd369a18"}).should eq(Array(Nil).new)
    end
  end

  it "commits_with_branch" do
    with_hg_repository("hg", "develop") do |hg|
      hg.commits.map { |c| c.token }.should eq(["01101d8ef3cea7da9ac6e9a226d645f4418f05c9",
                                                "b14fa4692f949940bd1e28da6fb4617de2615484",
                                                "468336c6671cbc58237a259d1b7326866afc2817",
                                                "75532c1e1f1de55c2271f6fd29d98efbe35397c4",
                                                "4d54c3f0526a1ec89214a70615a6b1c6129c665c"])

      hg.commits({:after => "75532c1e1f1de55c2271f6fd29d98efbe35397c4"}).map { |c| c.token }.should eq(
        ["4d54c3f0526a1ec89214a70615a6b1c6129c665c"])

      # Check that the diffs are not populated
      hg.commits({:after => "75532c1e1f1de55c2271f6fd29d98efbe35397c4"}).first.diffs.should eq(Array(Nil).new)

      hg.commits({:after => "4d54c3f0526a1ec89214a70615a6b1c6129c665c"}).should eq(Array(Nil).new)
    end
  end

  it "trunk_only_commit_count" do
    with_hg_repository("hg_dupe_delete") do |hg|
      hg.commit_count({:trunk_only => false}).should eq(4)
      hg.commit_count({:trunk_only => true}).should eq(3)
    end
  end

  it "trunk_only_commit_tokens" do
    with_hg_repository("hg_dupe_delete") do |hg|
      hg.commit_tokens({:trunk_only => false}).should eq(["73e93f57224e3fd828cf014644db8eec5013cd6b",
                                                "732345b1d5f4076498132fd4b965b1fec0108a50",
                                                "525de321d8085bc1d4a3c7608fda6b4020027985", # On branch
                                                "72fe74d643bdcb30b00da3b58796c50f221017d0"])

      hg.commit_tokens({:trunk_only => true}).should eq(["73e93f57224e3fd828cf014644db8eec5013cd6b",
                                                       "732345b1d5f4076498132fd4b965b1fec0108a50",
                                                       # "525de321d8085bc1d4a3c7608fda6b4020027985", # On branch
                                                       "72fe74d643bdcb30b00da3b58796c50f221017d0"])
    end
  end

  it "trunk_only_commit_tokens_using_after" do
    with_hg_repository("hg_dupe_delete") do |hg|

      hg.commit_tokens({:after => "73e93f57224e3fd828cf014644db8eec5013cd6b", :trunk_only => false}).should eq(
        ["732345b1d5f4076498132fd4b965b1fec0108a50",
        "525de321d8085bc1d4a3c7608fda6b4020027985", # On branch
        "72fe74d643bdcb30b00da3b58796c50f221017d0"])

      hg.commit_tokens({:after => "73e93f57224e3fd828cf014644db8eec5013cd6b", :trunk_only => true}).should eq(
        ["732345b1d5f4076498132fd4b965b1fec0108a50",
        # "525de321d8085bc1d4a3c7608fda6b4020027985", # On branch
        "72fe74d643bdcb30b00da3b58796c50f221017d0"])

      hg.commit_tokens({:after => "72fe74d643bdcb30b00da3b58796c50f221017d0", :trunk_only => true}).should eq(Array(Nil).new)
    end
  end

  it "trunk_only_commits" do
    with_hg_repository("hg_dupe_delete") do |hg|
      hg.commits({:trunk_only => true}).map { |c| c.token }.should eq(["73e93f57224e3fd828cf014644db8eec5013cd6b",
                                                                    "732345b1d5f4076498132fd4b965b1fec0108a50",
                                                                    # "525de321d8085bc1d4a3c7608fda6b4020027985", # On branch
                                                                    "72fe74d643bdcb30b00da3b58796c50f221017d0"])

    end
  end

  it "each_commit" do
    commits = Array(Nil).new
    with_hg_repository("hg") do |hg|
      hg.each_commit do |c|
        c.token.length == 40.should be_truthy
        c.committer_name.should be_truthy
        c.committer_date.is_a?(Time).should be_truthy
        c.message.length > 0.should be_truthy
        c.diffs.any?.should be_truthy
        # Check that the diffs are populated
        c.diffs.each do |d|
          d.action =~ /^[MAD]$/.should be_truthy
          d.path.length > 0.should be_truthy
        end
        commits << c
      end
      FileTest.exist?(hg.log_filename).should be_falsey # Make sure we cleaned up after ourselves

      # Verify that we got the commits in forward chronological order
      commits.map { |c| c.token }.should eq(["01101d8ef3cea7da9ac6e9a226d645f4418f05c9",
                                             "b14fa4692f949940bd1e28da6fb4617de2615484",
                                             "468336c6671cbc58237a259d1b7326866afc2817",
                                             "75532c1e1f1de55c2271f6fd29d98efbe35397c4",
                                             "655f04cf6ad708ab58c7b941672dce09dd369a18"])
    end
  end

  it "each_commit_for_branch" do
    commits = Array(Nil).new

    with_hg_repository("hg", "develop") do |hg|
      commits = hg.each_commit
    end

    commits.map { |c| c.token }.should eq(["01101d8ef3cea7da9ac6e9a226d645f4418f05c9",
                                           "b14fa4692f949940bd1e28da6fb4617de2615484",
                                           "468336c6671cbc58237a259d1b7326866afc2817",
                                           "75532c1e1f1de55c2271f6fd29d98efbe35397c4",
                                           "4d54c3f0526a1ec89214a70615a6b1c6129c665c"])
  end


  it "each_commit_after" do
    commits = Array(Nil).new
    with_hg_repository("hg") do |hg|
      hg.each_commit({:after => "468336c6671cbc58237a259d1b7326866afc2817"}) do |c|
        commits << c
      end
      commits.map { |c| c.token }.should eq(["75532c1e1f1de55c2271f6fd29d98efbe35397c4",
                                             "655f04cf6ad708ab58c7b941672dce09dd369a18"])
    end
  end

  it "open_log_file_encoding" do
    with_hg_repository("hg_with_invalid_encoding") do |hg|
      hg.open_log_file do |io|
        io.read.valid_encoding?.should eq(true)
      end
    end
  end

  it "log_encoding" do
    with_hg_repository("hg_with_invalid_encoding") do |hg|
      hg.log.valid_encoding?.should eq(true)
    end
  end

  it "commits_encoding" do
    with_hg_repository("hg_with_invalid_encoding") do |hg|
      hg.commits
    end
  end

  it "verbose_commit_encoding" do
    with_hg_repository("hg_with_invalid_encoding") do |hg|
      hg.verbose_commit("51ea5277ca27")
    end
  end
end
