require "../test_helper"

describe "SvnCommits" do

  it "commits" do
    with_svn_repository("svn") do |svn|
      svn.commit_count.should eq(5)
      svn.commit_count(:after => 2).should eq(3)
      svn.commit_count(:after => 1000).should eq(0)

      svn.commit_tokens.should eq([1,2,3,4,5])
      svn.commit_tokens(:after => 2).should eq([3,4,5])
      svn.commit_tokens(:after => 1000).should eq([])

      svn.commits.map { |c| c.token }.should eq([1,2,3,4,5])
      svn.commits(:after => 2).map { |c| c.token }.should eq([3,4,5])
      svn.commits(:after => 1000).should eq([])
      FileTest.exist?(svn.log_filename).should be_falsey
    end
  end

  # Confirms that the sha1 matches those created by git exactly
  it "sha1" do
    with_svn_repository("svn") do |svn|
      svn.compute_sha1(nil).should eq("0000000000000000000000000000000000000000")
      svn.compute_sha1("").should eq("0000000000000000000000000000000000000000")
      svn.compute_sha1("test").should eq("30d74d258442c7c65512eafab474568dd706c430")
    end
  end

  # Given a commit with diffs, fill in all of the SHA1 values.
  it "populate_sha1" do
    with_svn_repository("svn") do |svn|
      c = OhlohScm::Commit.new(:token => 3)
      c.diffs = [OhlohScm::Diff.new(:path => "/trunk/helloworld.c", :action => "M")]
      svn.populate_commit_sha1s!(c)
      c.diffs.first.sha1.should eq("f6adcae4447809b651c787c078d255b2b4e963c5")
      c.diffs.first.parent_sha1.should eq("4c734ad53b272c9b3d719f214372ac497ff6c068")
    end
  end

  it "strip_commit_branch" do
    svn = SvnAdapter.new(:branch_name => "/trunk")
    commit = OhlohScm::Commit.new

    # nil diffs before => nil diffs after
    svn.strip_commit_branch(commit).diffs.should be_falsey

    # [] diffs before => [] diffs after
    commit.diffs = []
    svn.strip_commit_branch(commit).diffs.should eq([])

    commit.diffs = [
      OhlohScm::Diff.new(:path => "/trunk"),
      OhlohScm::Diff.new(:path => "/trunk/helloworld.c"),
      OhlohScm::Diff.new(:path => "/branches/a")
    ]
    svn.strip_commit_branch(commit).diffs.map { |d| d.path }.sort.should eq(["", "/helloworld.c"])
  end

  it "strip_diff_branch" do
    svn = SvnAdapter.new(:branch_name => "/trunk")
    svn.strip_diff_branch(OhlohScm::Diff.new).should be_falsey
    svn.strip_diff_branch(OhlohScm::Diff.new(:path => "/branches/b")).should be_falsey
    svn.strip_diff_branch(OhlohScm::Diff.new(:path => "/trunk")).path.should eq("")
    svn.strip_diff_branch(OhlohScm::Diff.new(:path => "/trunk/helloworld.c")).path.should eq("/helloworld.c")
  end

  it "strip_path_branch" do
    # Returns nil for any path outside of SvnAdapter::branch_name
    SvnAdapter.new.strip_path_branch(nil).should be_falsey
    SvnAdapter.new(:branch_name => "/trunk").strip_path_branch("/branches/foo").should be_falsey
    SvnAdapter.new(:branch_name => "/trunk").strip_path_branch("/t").should be_falsey

    # If branch_name is empty or root, returns path unchanged
    SvnAdapter.new.strip_path_branch("").should eq("")
    SvnAdapter.new.strip_path_branch("/trunk").should eq("/trunk")

    # If path is equal to or is a subdirectory of branch_name, returns subdirectory portion only.
    SvnAdapter.new(:branch_name => "/trunk").strip_path_branch("/trunk").should eq("")
    SvnAdapter.new(:branch_name => "/trunk").strip_path_branch("/trunk/foo").should eq("/foo")
  end

  it "strip_path_branch_with_special_chars" do
    SvnAdapter.new(:branch_name => "/trunk/hamcrest-c++").strip_path_branch("/trunk/hamcrest-c++/foo").should eq("/foo")
  end

  it "remove_dupes_add_modify" do
    svn = SvnAdapter.new
    c = OhlohScm::Commit.new(:diffs => [ OhlohScm::Diff.new(:action => "A", :path => "foo"),
                                    OhlohScm::Diff.new(:action => "M", :path => "foo") ])

    svn.remove_dupes(c)
    c.diffs.size.should eq(1)
    c.diffs.first.action.should eq("A")
  end

  it "remove_dupes_add_replace" do
    svn = SvnAdapter.new
    c = OhlohScm::Commit.new(:diffs => [ OhlohScm::Diff.new(:action => "R", :path => "foo"),
                                    OhlohScm::Diff.new(:action => "A", :path => "foo") ])

    svn.remove_dupes(c)
    c.diffs.size.should eq(1)
    c.diffs.first.action.should eq("A")
  end

  # Had so many bugs around this case that a test was required
  it "deepen_commit_with_nil_diffs" do
    with_svn_repository("svn") do |svn|
      c = svn.commits.first # Doesn"t matter which
      c.diffs = nil
      svn.populate_commit_sha1s!(svn.deepen_commit(c)) # If we don"t crash we pass the test.
    end
  end

  it "deep_commits" do
    with_svn_repository("deep_svn") do |svn|

      # The full repository contains 4 revisions...
      svn.commit_count.should eq(4)

      # ...however, the current trunk contains only revisions 3 and 4.
      # That"s because the branch was moved to replace the trunk at revision 3.
      #
      # Even though there was a different trunk directory present in
      # revisions 1 and 2, it is not visible to Ohloh.

      trunk = SvnAdapter.new(:url => File.join(svn.url,"trunk"), :branch_name => "/trunk").normalize
      trunk.commit_count.should eq(2)
      trunk.commit_tokens.should eq([3,4])


      deep_commits = []
      trunk.each_commit { |c| deep_commits << c }

      # When the branch is moved to replace the trunk in revision 3,
      # the Subversion log shows
      #
      #   D /branches/b
      #   A /trunk (from /branches/b:2)
      #
      # However, there are files in those directories. Make sure the commits
      # that we generate include all of those files not shown by the log.
      #
      # Also, our commits do not include diffs for the actual directories;
      # only the files within those directories.
      #
      # Also, after we are only tracking the /trunk and not /branches/b, then
      # there should not be anything referring to activity in /branches/b.

      deep_commits.first.token.should eq(3) # Make sure this is the right revision
      deep_commits.first.diffs.size.should eq(2) # Two files seen

      deep_commits.first.diffs[0].action.should eq("A")
      deep_commits.first.diffs[0].path.should eq("/subdir/bar.rb")
      deep_commits.first.diffs[1].action.should eq("A")
      deep_commits.first.diffs[1].path.should eq("/subdir/foo.rb")

      # In Revision 4, a directory is renamed. This shows in the Subversion log as
      #
      #   A /trunk/newdir (from /trunk/subdir:3)
      #   D /trunk/subdir
      #
      # Again, there are files in this directory, so make sure our commit includes
      # both delete and add events for all of the files in this directory, but does
      # not actually refer to the directories themselves.

      deep_commits.last.token.should eq(4) # Make sure we"re checking the right revision

      # There should be 2 files removed and two files added
      deep_commits.last.diffs.size.should eq(4)

      deep_commits.last.diffs[0].action.should eq("A")
      deep_commits.last.diffs[0].path.should eq("/newdir/bar.rb")
      deep_commits.last.diffs[1].action.should eq("A")
      deep_commits.last.diffs[1].path.should eq("/newdir/foo.rb")

      deep_commits.last.diffs[2].action.should eq("D")
      deep_commits.last.diffs[2].path.should eq("/subdir/bar.rb")
      deep_commits.last.diffs[3].action.should eq("D")
      deep_commits.last.diffs[3].path.should eq("/subdir/foo.rb")
    end
  end

  # A mini-integration test.
  # Check that SHA1 values are populated, directories are recursed, and outside branches are ignored.
  it "each_commit" do
    commits = []
    with_svn_repository("svn") do |svn|
      svn.each_commit do |e|
        commits << e
        e.token.to_s =~ /\d+/.should be_truthy
        e.committer_name.length > 0.should be_truthy
        e.committer_date.is_a?(Time).should be_truthy
        e.message.should be_truthy
        e.diffs.any?.should be_truthy
        e.diffs.each do |d|
          d.action.length == 1.should be_truthy
          d.path.length > 0.should be_truthy
        end
      end
      FileTest.exist?(svn.log_filename).should be_falsey # Make sure we cleaned up after ourselves
    end

    commits.map { |c| c.token }.should eq([1, 2, 3, 4, 5])
    commits.map { |c| c.committer_name }.should eq(["robin","robin","robin","jason","jason"])

    commits[0].committer_date.should eq(Time.utc(2006,6,11,18,28, 0))
    commits[1].committer_date.should eq(Time.utc(2006,6,11,18,32,14))
    commits[2].committer_date.should eq(Time.utc(2006,6,11,18,34,18))
    commits[3].committer_date.should eq(Time.utc(2006,7,14,22,17, 9))
    commits[4].committer_date.should eq(Time.utc(2006,7,14,23, 7,16))

    commits[0].message.should eq("Initial Checkin\n")
    commits[1].message.should eq("added makefile")
    commits[2].message.should eq("added some documentation and licensing info")
    commits[3].message.should eq("added bs COPYING to catch global licenses")
    commits[4].message.should eq("moving COPYING")

    commits[0].diffs.size.should eq(1)
    commits[0].diffs[0].action.should eq("A")
    commits[0].diffs[0].path.should eq("/trunk/helloworld.c")

    commits[1].diffs.size.should eq(1)
    commits[1].diffs[0].action.should eq("A")
    commits[1].diffs[0].path.should eq("/trunk/makefile")

    commits[2].diffs.size.should eq(2)
    commits[2].diffs[0].action.should eq("A")
    commits[2].diffs[0].path.should eq("/trunk/README")
    commits[2].diffs[1].action.should eq("M")
    commits[2].diffs[1].path.should eq("/trunk/helloworld.c")

    commits[3].diffs.size.should eq(1)
    commits[3].diffs[0].action.should eq("A")
    commits[3].diffs[0].path.should eq("/COPYING")

    commits[4].diffs.size.should eq(2)
    commits[4].diffs[0].action.should eq("D")
    commits[4].diffs[0].path.should eq("/COPYING")
    commits[4].diffs[1].action.should eq("A")
    commits[4].diffs[1].path.should eq("/trunk/COPYING")
  end

  it "log_valid_encoding" do
    with_invalid_encoded_svn_repository do |svn|
      svn.log.valid_encoding?.should eq(true)
    end
  end

  it "commits_encoding" do
    with_invalid_encoded_svn_repository do |svn|
      svn.commits rescue raise Exception
    end
  end

  it "open_log_file_encoding" do
    with_invalid_encoded_svn_repository do |svn|
      svn.open_log_file do |io|
        io.read.valid_encoding?.should eq(true)
      end
    end
  end

  it "single_revision_xml_valid_encoding" do
    with_invalid_encoded_svn_repository do |svn|
      svn.single_revision_xml(:anything).valid_encoding?.should eq(true)
    end
  end
end
