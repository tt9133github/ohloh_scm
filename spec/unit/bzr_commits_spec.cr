require "../test_helper"

describe "BzrCommits" do

  it "commit_count" do
    with_bzr_repository("bzr") do |bzr|
      bzr.commit_count.should eq(7)
      bzr.commit_count(:after => revision_ids.first).should eq(6)
      bzr.commit_count(:after => revision_ids[5]).should eq(1)
      bzr.commit_count(:after => revision_ids.last).should eq(0)
    end
  end

  it "commit_count_with_branches" do
    with_bzr_repository("bzr_with_branch") do |bzr|
      # Only 3 commits are on main line... make sure we catch the branch commit as well
      bzr.commit_count.should eq(4)
    end
  end

  it "commit_count_after_merge" do
    with_bzr_repository("bzr_with_branch") do |bzr|
      last_commit = bzr.commits.last
      bzr.commit_count(:trunk_only => false, :after => last_commit.token).should eq(0)
    end
  end

  it "commit_count_trunk_only" do
    with_bzr_repository("bzr_with_branch") do |bzr|
      # Only 3 commits are on main line
      bzr.commit_count(:trunk_only => true).should eq(3)
    end
  end

  it "commit_tokens_after" do
    with_bzr_repository("bzr") do |bzr|
      bzr.commit_tokens.should eq(revision_ids)
      bzr.commit_tokens(:after => revision_ids.first).should eq(revision_ids[1..6])
      bzr.commit_tokens(:after => revision_ids[5]).should eq(revision_ids[6..6])
      bzr.commit_tokens(:after => revision_ids.last).should eq([])
    end
  end

  it "commit_tokens_after_merge" do
    with_bzr_repository("bzr_with_branch") do |bzr|
      last_commit = bzr.commits.last
      bzr.commit_tokens(:trunk_only => false, :after => last_commit.token).should eq([])
    end
  end

  it "commit_tokens_after_nested_merge" do
    with_bzr_repository("bzr_with_nested_branches") do |bzr|
      last_commit = bzr.commits.last
      bzr.commit_tokens(:trunk_only => false, :after => last_commit.token).should eq([])
    end
  end

  it "commit_tokens_trunk_only_false" do
    # Funny business with commit ordering has been fixed by BzrXmlParser.
    # Now we always see branch commits before merge commit.
    with_bzr_repository("bzr_with_branch") do |bzr|
      bzr.commit_tokens(:trunk_only => false).should eq([
        "test@example.com-20090206214301-s93cethy9atcqu9h",
        "test@example.com-20090206214451-lzjngefdyw3vmgms",
        "test@example.com-20090206214350-rqhdpz92l11eoq2t", # branch commit
        "test@example.com-20090206214515-21lkfj3dbocao5pr"  # merge commit
      ])
    end
  end

  it "commit_tokens_trunk_only_true" do
    with_bzr_repository("bzr_with_branch") do |bzr|
      bzr.commit_tokens(:trunk_only => true).should eq([
        "test@example.com-20090206214301-s93cethy9atcqu9h",
        "test@example.com-20090206214451-lzjngefdyw3vmgms",
        "test@example.com-20090206214515-21lkfj3dbocao5pr"  # merge commit
      ])
    end
  end

  it "nested_branches_commit_tokens_trunk_only_false" do
    with_bzr_repository("bzr_with_nested_branches") do |bzr|
      bzr.commit_tokens(:trunk_only => false).should eq([
        "obnox@samba.org-20090204002342-5r0q4gejk69rk6uv",
        "obnox@samba.org-20090204002422-5ylnq8l4713eqfy0",
        "obnox@samba.org-20090204002453-u70a3ehf3ae9kay1",
        "obnox@samba.org-20090204002518-yb0x153oa6mhoodu",
        "obnox@samba.org-20090204002540-gmana8tk5f9gboq9",
        "obnox@samba.org-20090204004942-73rnw0izen42f154",
        "test@example.com-20110803170302-fz4mbr89n8f5agha",
        "test@example.com-20110803170341-v1icvy05b430t68l",
        "test@example.com-20110803170504-z7xz5uxj02e5x3z6",
        "test@example.com-20110803170522-asv6i9z6m22jc8zz",
        "test@example.com-20110803170648-o0xcbni7lwp97azj",
        "test@example.com-20110803170818-v44umypquqg8migo"
      ])
    end
  end

  it "nested_branches_commit_tokens_trunk_only_true" do
    with_bzr_repository("bzr_with_nested_branches") do |bzr|
      bzr.commit_tokens(:trunk_only => true).should eq([
        "obnox@samba.org-20090204002342-5r0q4gejk69rk6uv",
        "obnox@samba.org-20090204002422-5ylnq8l4713eqfy0",
        "obnox@samba.org-20090204002453-u70a3ehf3ae9kay1",
        "obnox@samba.org-20090204002518-yb0x153oa6mhoodu",
        "obnox@samba.org-20090204002540-gmana8tk5f9gboq9",
        "obnox@samba.org-20090204004942-73rnw0izen42f154",
        "test@example.com-20110803170818-v44umypquqg8migo"
      ])
    end
  end

  it "commits_trunk_only_false" do
    with_bzr_repository("bzr_with_branch") do |bzr|
      bzr.commits(:trunk_only => false).map { |c| c.token }.should eq([
        "test@example.com-20090206214301-s93cethy9atcqu9h",
        "test@example.com-20090206214451-lzjngefdyw3vmgms",
        "test@example.com-20090206214350-rqhdpz92l11eoq2t", # branch commit
        "test@example.com-20090206214515-21lkfj3dbocao5pr"  # merge commit
      ])
    end
  end

  it "commits_trunk_only_true" do
    with_bzr_repository("bzr_with_branch") do |bzr|
      bzr.commits(:trunk_only => true).map { |c| c.token }.should eq([
        "test@example.com-20090206214301-s93cethy9atcqu9h",
        "test@example.com-20090206214451-lzjngefdyw3vmgms",
        "test@example.com-20090206214515-21lkfj3dbocao5pr"  # merge commit
      ])
    end
  end

  it "commits_after_merge" do
    with_bzr_repository("bzr_with_branch") do |bzr|
      last_commit = bzr.commits.last
      bzr.commits(:trunk_only => false, :after => last_commit.token).should eq([])
    end
  end

  it "commits_after_nested_merge" do
    with_bzr_repository("bzr_with_nested_branches") do |bzr|
      last_commit = bzr.commits.last
      bzr.commits(:trunk_only => false, :after => last_commit.token).should eq([])
    end
  end

  it "nested_branches_commits_trunk_only_false" do
    with_bzr_repository("bzr_with_nested_branches") do |bzr|
      bzr.commits(:trunk_only => false).map { |c| c.token }.should eq([
        "obnox@samba.org-20090204002342-5r0q4gejk69rk6uv",
        "obnox@samba.org-20090204002422-5ylnq8l4713eqfy0",
        "obnox@samba.org-20090204002453-u70a3ehf3ae9kay1",
        "obnox@samba.org-20090204002518-yb0x153oa6mhoodu",
        "obnox@samba.org-20090204002540-gmana8tk5f9gboq9",
        "obnox@samba.org-20090204004942-73rnw0izen42f154",
        "test@example.com-20110803170302-fz4mbr89n8f5agha",
        "test@example.com-20110803170341-v1icvy05b430t68l",
        "test@example.com-20110803170504-z7xz5uxj02e5x3z6",
        "test@example.com-20110803170522-asv6i9z6m22jc8zz",
        "test@example.com-20110803170648-o0xcbni7lwp97azj",
        "test@example.com-20110803170818-v44umypquqg8migo"
      ])
    end
  end

  it "nested_branches_commits_trunk_only_true" do
    with_bzr_repository("bzr_with_nested_branches") do |bzr|
      bzr.commits(:trunk_only => true).map { |c| c.token }.should eq([
        "obnox@samba.org-20090204002342-5r0q4gejk69rk6uv",
        "obnox@samba.org-20090204002422-5ylnq8l4713eqfy0",
        "obnox@samba.org-20090204002453-u70a3ehf3ae9kay1",
        "obnox@samba.org-20090204002518-yb0x153oa6mhoodu",
        "obnox@samba.org-20090204002540-gmana8tk5f9gboq9",
        "obnox@samba.org-20090204004942-73rnw0izen42f154",
        "test@example.com-20110803170818-v44umypquqg8migo"
      ])
    end
  end

  it "commits" do
    with_bzr_repository("bzr") do |bzr|
      bzr.commits.map { |c| c.token }.should eq(revision_ids)
      bzr.commits(:after => revision_ids[5]).map { |c| c.token }.should eq(revision_ids[6..6])
      bzr.commits(:after => revision_ids.last).map { |c| c.token }.should eq([])

      # Check that the diffs are not populated
      bzr.commits.first.diffs.should eq([])
    end
  end

  it "each_commit" do
    with_bzr_repository("bzr") do |bzr|
      commits = []
      bzr.each_commit do |c|
        c.committer_name.should be_truthy
        c.committer_date.is_a?(Time).should be_truthy
        c.message.length.should be > 0
        c.diffs.any?.should be_truthy
        # Check that the diffs are populated
        c.diffs.each do |d|
          d.action.should match(/^[MAD]$/)
          d.path.length should be > 0
        end
        commits << c
      end

      # Make sure we cleaned up after ourselves
      FileTest.exist?(bzr.log_filename).should be_falsey

      # Verify that we got the commits in forward chronological order
      commits.map{ |c| c.token }.should eq(revision_ids)
    end
  end

  it "each_commit_trunk_only_false" do
    with_bzr_repository("bzr_with_branch") do |bzr|
      commits = []
      bzr.each_commit(:trunk_only => false) { |c| commits << c }
      commits.map { |c| c.token }.should eq([
        "test@example.com-20090206214301-s93cethy9atcqu9h",
        "test@example.com-20090206214451-lzjngefdyw3vmgms",
        "test@example.com-20090206214350-rqhdpz92l11eoq2t", # branch commit
        "test@example.com-20090206214515-21lkfj3dbocao5pr"  # merge commit
      ])
    end
  end

  it "each_commit_trunk_only_true" do
    with_bzr_repository("bzr_with_branch") do |bzr|
      commits = []
      bzr.each_commit(:trunk_only => true) { |c| commits << c }
      commits.map { |c| c.token }.should eq([
        "test@example.com-20090206214301-s93cethy9atcqu9h",
        "test@example.com-20090206214451-lzjngefdyw3vmgms",
        "test@example.com-20090206214515-21lkfj3dbocao5pr"   # merge commit
        # "test@example.com-20090206214350-rqhdpz92l11eoq2t" # branch commit -- after merge!
      ])
    end
  end

  it "each_commit_after_merge" do
    with_bzr_repository("bzr_with_branch") do |bzr|
      last_commit = bzr.commits.last

      commits = []
      bzr.each_commit(:trunk_only => false, :after => last_commit.token) { |c| commits << c }
      commits.should eq([])
    end
  end

  it "each_commit_after_nested_merge_at_tip" do
    with_bzr_repository("bzr_with_nested_branches") do |bzr|
      last_commit = bzr.commits.last

      commits = []
      bzr.each_commit(:trunk_only => false, :after => last_commit.token) { |c| commits << c }
      commits.should eq([])
    end
  end

  it "each_commit_after_nested_merge_not_at_tip" do
    with_bzr_repository("bzr_with_nested_branches") do |bzr|
      last_commit = bzr.commits.last
      next_to_last_commit = bzr.commits[-2]

      yielded_commits = []
      bzr.each_commit(:trunk_only => false, :after => next_to_last_commit.token) { |c| yielded_commits << c }
      yielded_commits.map(&:token).should eq([last_commit.token])
    end
  end

  it "nested_branches_each_commit_trunk_only_false" do
    with_bzr_repository("bzr_with_nested_branches") do |bzr|
      commits = []
      bzr.each_commit(:trunk_only => false) { |c| commits << c}
      commits.map { |c| c.token }.should eq([
        "obnox@samba.org-20090204002342-5r0q4gejk69rk6uv",
        "obnox@samba.org-20090204002422-5ylnq8l4713eqfy0",
        "obnox@samba.org-20090204002453-u70a3ehf3ae9kay1",
        "obnox@samba.org-20090204002518-yb0x153oa6mhoodu",
        "obnox@samba.org-20090204002540-gmana8tk5f9gboq9",
        "obnox@samba.org-20090204004942-73rnw0izen42f154",
        "test@example.com-20110803170302-fz4mbr89n8f5agha",
        "test@example.com-20110803170341-v1icvy05b430t68l",
        "test@example.com-20110803170504-z7xz5uxj02e5x3z6",
        "test@example.com-20110803170522-asv6i9z6m22jc8zz",
        "test@example.com-20110803170648-o0xcbni7lwp97azj",
        "test@example.com-20110803170818-v44umypquqg8migo"
      ])
    end
  end

  it "nested_branches_each_commit_trunk_only_true" do
    with_bzr_repository("bzr_with_nested_branches") do |bzr|
      commits = []
      bzr.each_commit(:trunk_only => true) { |c| commits << c }
      commits.map { |c| c.token }.should eq([
        "obnox@samba.org-20090204002342-5r0q4gejk69rk6uv",
        "obnox@samba.org-20090204002422-5ylnq8l4713eqfy0",
        "obnox@samba.org-20090204002453-u70a3ehf3ae9kay1",
        "obnox@samba.org-20090204002518-yb0x153oa6mhoodu",
        "obnox@samba.org-20090204002540-gmana8tk5f9gboq9",
        "obnox@samba.org-20090204004942-73rnw0izen42f154",
        "test@example.com-20110803170818-v44umypquqg8migo"
      ])
    end
  end

  # This bzr repository contains the following tree structure
  #    /foo/
  #    /foo/helloworld.c
  #    /bar/
  # Ohloh doesn"t care about directories, so only /foo/helloworld.c should be reported.
  it "each_commit_excludes_directories" do
    with_bzr_repository("bzr_with_subdirectories") do |bzr|
      commits = []
      bzr.each_commit do |c|
        commits << c
      end
      commits.size.should eq(1)
      commits.first.diffs.size.should eq(1)
      commits.first.diffs.first.path.should eq("foo/helloworld.c")
    end
  end

  # Verfies OTWO-344
  it "commit_tokens_with_colon_character" do
    with_bzr_repository("bzr_colon") do |bzr|
      bzr.commit_tokens.should eq(["svn-v4:364a429a-ab12-11de-804f-e3d9c25ff3d2::0"])
    end
  end

  it "committer_and_author_name" do
    with_bzr_repository("bzr_with_authors") do |bzr|
      commits = []
      bzr.each_commit do |c|
        commits << c
      end
      commits.size.should eq(3)

      commits[0].message.should eq("Initial.")
      commits[0].committer_name.should eq("Abhay Mujumdar")
      commits[0].author_name.should eq(nil)
      commits[0].author_email.should eq(nil)

      commits[1].message.should eq("Updated.")
      commits[1].committer_name.should eq("Abhay Mujumdar")
      commits[1].author_name.should eq("John Doe")
      commits[1].author_email.should eq("johndoe@example.com")

      # When there are multiple authors, first one is captured.
      commits[2].message.should eq("Updated by two authors.")
      commits[2].committer_name.should eq("test")
      commits[2].author_name.should eq("John Doe")
      commits[2].author_email.should eq("johndoe@example.com")
    end
  end

  # Bzr converts invalid utf-8 characters into valid format before commit.
  # So no utf-8 encoding issues are seen in ruby when dealing with Bzr.
  it "commits_encoding" do
    with_bzr_repository("bzr_with_invalid_encoding") do |bzr|
      bzr.commits
    end
  end

  protected

  def revision_ids
    [
      "obnox@samba.org-20090204002342-5r0q4gejk69rk6uv", # 1
      "obnox@samba.org-20090204002422-5ylnq8l4713eqfy0", # 2
      "obnox@samba.org-20090204002453-u70a3ehf3ae9kay1", # 3
      "obnox@samba.org-20090204002518-yb0x153oa6mhoodu", # 4
      "obnox@samba.org-20090204002540-gmana8tk5f9gboq9", # 5
      "obnox@samba.org-20090204004942-73rnw0izen42f154", # 6
      "test@example.com-20111222183733-y91if5npo3pe8ifs", # 7
    ]
  end

end
