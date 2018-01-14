require "../spec_helper"

describe "SvnChain" do

  it "chained_commit_tokens" do
    with_svn_chain_repository("svn_with_branching", "/trunk") do |svn|
      svn.commit_tokens.should eq([1,2,4,5,8,9,11])
      svn.commit_tokens({:after => 1}).should eq([2,4,5,8,9,11])
      svn.commit_tokens({:after => 2}).should eq([4,5,8,9,11])
      svn.commit_tokens({:after => 3}).should eq([4,5,8,9,11])
      svn.commit_tokens({:after => 4}).should eq([5,8,9,11])
      svn.commit_tokens({:after => 5}).should eq([8,9,11])
      svn.commit_tokens({:after => 6}).should eq([8,9,11])
      svn.commit_tokens({:after => 7}).should eq([8,9,11])
      svn.commit_tokens({:after => 8}).should eq([9,11])
      svn.commit_tokens({:after => 9}).should eq([11])
      svn.commit_tokens({:after => 11}).should eq([])
    end
  end

  it "chained_commit_count" do
    with_svn_chain_repository("svn_with_branching", "/trunk") do |svn|
      svn.commit_count.should eq(7)
      svn.commit_count({:after => 1}).should eq(6)
      svn.commit_count({:after => 2}).should eq(5)
      svn.commit_count({:after => 3}).should eq(5)
      svn.commit_count({:after => 4}).should eq(4)
      svn.commit_count({:after => 5}).should eq(3)
      svn.commit_count({:after => 6}).should eq(3)
      svn.commit_count({:after => 7}).should eq(3)
      svn.commit_count({:after => 8}).should eq(2)
      svn.commit_count({:after => 9}).should eq(1)
      svn.commit_count({:after => 11}).should eq(0)
    end
  end

  it "chained_commits" do
    with_svn_chain_repository("svn_with_branching", "/trunk") do |svn|
      svn.commits.map { |c| c.token }.should eq([1,2,4,5,8,9,11])
      svn.commits({:after => 1}).map { |c| c.token }.should eq([2,4,5,8,9,11])
      svn.commits({:after => 2}).map { |c| c.token }.should eq([4,5,8,9,11])
      svn.commits({:after => 3}).map { |c| c.token }.should eq([4,5,8,9,11])
      svn.commits({:after => 4}).map { |c| c.token }.should eq([5,8,9,11])
      svn.commits({:after => 5}).map { |c| c.token }.should eq([8,9,11])
      svn.commits({:after => 6}).map { |c| c.token }.should eq([8,9,11])
      svn.commits({:after => 7}).map { |c| c.token }.should eq([8,9,11])
      svn.commits({:after => 8}).map { |c| c.token }.should eq([9,11])
      svn.commits({:after => 9}).map { |c| c.token }.should eq([11])
      svn.commits({:after => 11}).map { |c| c.token }.should eq([])
    end
  end

  # This test is primarly concerned with the checking the diffs
  # of commits. Specifically, when an entire branch is moved
  # to a new name, we should not see any diffs. From our
  # point of view the code is unchanged; only the base directory
  # has moved.
  it "chained_each_commit" do
    commits = []
    with_svn_chain_repository("svn_with_branching", "/trunk") do |svn|
      svn.each_commit do |c|
        c.scm.should be_truthy # To support checkout of chained commits, the
                     # commit must include a link to its containing adapter.
        commits << c
      end
    end

    commits.map { |c| c.token }.should eq([1,2,4,5,8,9,11])

    # This repository spends a lot of energy moving directories around.
    # File edits actually occur in just 3 commits.

    # Revision 1: /trunk directory created, but it is empty
    commits[0].diffs.size.should eq(0)

    # Revision 2: /trunk/helloworld.c is added
    commits[1].diffs.size.should eq(1)
    commits[1].diffs.first.action.should eq("A")
    commits[1].diffs.first.path.should eq("/helloworld.c")

    # Revision 3: /trunk is deleted. We can"t see this revision.

    # Revision 4: /trunk is re-created by copying it from revision 2.
    # From our point of view, there has been no change at all, and thus no diffs.
    commits[2].diffs.size.should eq(0)

    # Revision 5: /branches/development is created by copying /trunk.
    # From our point of view, the contents of the repository are unchanged, so
    # no diffs result from the copy.
    # However, /branches/development/goodbyeworld.c is also created, so we should
    # have a diff for that.
    commits[3].diffs.size.should eq(1)
    commits[3].diffs.first.action.should eq("A")
    commits[3].diffs.first.path.should eq("/goodbyeworld.c")

    # Revision 6: /trunk/goodbyeworld.c is created, but we only see activity
    # on /branches/development, so no commit reported.

    # Revision 7: /trunk is deleted, but again we don"t see it.

    # Revision 8: /branches/development is moved to become the new /trunk.
    # The directory contents are unchanged, so no diffs result.
    commits[4].diffs.size.should eq(0)

    # Revision 9: an edit to /trunk/helloworld.c
    commits[5].diffs.size.should eq(1)
    commits[5].diffs.first.action.should eq("M")
    commits[5].diffs.first.path.should eq("/helloworld.c")

    # Revision 10: /trunk/goodbyeworld.c & /trunk/helloworld.c are modified
    # on branches/development, hence no commit reported.

    # Revision 11: The trunk is reverted back to revision 9.
    commits[6].diffs.size.should eq(0)
  end

  # Specifically tests this case:
  # Suppose we're importing /myproject/trunk, and the log
  # contains the following:
  #
  #   A /myproject (from /all/myproject:1)
  #   D /all/myproject
  #
  # We need to make sure we detect the move here, even though
  # "/myproject" is not an exact match for "/myproject/trunk".
  it "tree_move" do
    with_svn_chain_repository("svn_with_tree_move", "/myproject/trunk") do |svn|
      svn.root + "/myproject/trunk".should eq(svn.url)
      "/myproject/trunk".should eq(svn.branch_name)

      p = svn.parent_svn
      svn.root + "/all/myproject/trunk".should eq(p.url)
      "/all/myproject/trunk".should eq(p.branch_name)
      1.should eq(p.final_token)

      svn.commit_tokens.should eq([1, 2])
    end
  end

  it "verbose_commit_with_chaining" do
    with_svn_chain_repository("svn_with_branching","/trunk") do |svn|

      c = svn.verbose_commit(9)
      c.message.should eq("modified helloworld.c")
      c.diffs.map { |d| d.path }.should eq(["/helloworld.c"])
      c.scm.branch_name.should eq("/trunk")

      c = svn.verbose_commit(8)
      c.diffs.should eq([])
      c.scm.branch_name.should eq("/trunk")

      # Reaching these commits requires chaining
      c = svn.verbose_commit(5)
      c.message.should eq("add a new branch, with goodbyeworld.c")
      c.diffs.map { |d| d.path }.should eq(["/goodbyeworld.c"])
      c.scm.branch_name.should eq("/branches/development")

      # Reaching these commits requires chaining twice
      c = svn.verbose_commit(4)
      c.diffs.should eq([])
      c.scm.branch_name.should eq("/trunk")

      # And now a fourth chain (to skip over /trunk deletion in rev 3)
      c = svn.verbose_commit(2)
      c.message.should eq("Added helloworld.c to trunk")
      c.diffs.map { |d| d.path }.should eq(["/helloworld.c"])
      c.scm.branch_name.should eq("/trunk")

      c = svn.verbose_commit(1)
      c.diffs.should eq([])
      c.scm.branch_name.should eq("/trunk")
    end
  end
end
