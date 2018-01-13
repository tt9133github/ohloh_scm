require "../test_helper"

describe "CvsParser" do

  it "basic" do
    assert_convert(CvsParser, DATA_DIR + "/basic.rlog", DATA_DIR + "/basic.ohlog")
  end

  it "empty_array" do
    CvsParser.parse("").should eq([])
  end

  it "empty_xml" do
    CvsParser.parse("", { :writer => XmlWriter.new }).should eq("<?xml version=\"1.0\"?>\n<ohloh_log scm=\"cvs\">\n</ohloh_log>\n")
  end

  it "log_parser" do
    revisions = CvsParser.parse File.read(DATA_DIR + "/basic.rlog")

    revisions.size.should eq(2)

    revisions[0].token.should eq("2005/07/25 17:09:59")
    revisions[0].committer_name.should eq("pizzandre")
    revisions[0].committer_date.should eq(Time.utc(2005,07,25,17,9,59))
    revisions[0].message.should eq("*** empty log message ***")

    revisions[1].token.should eq("2005/07/25 17:11:06")
    revisions[1].committer_name.should eq("pizzandre")
    revisions[1].committer_date.should eq(Time.utc(2005,07,25,17,11,6))
    revisions[1].message.should eq("Addin UNL file with using example-")
  end

  # One file with several revisions
  it "multiple_revisions" do
    revisions = CvsParser.parse File.read(DATA_DIR + "/multiple_revisions.rlog")

    # There are 9 revisions in the rlog, but some of them are close together with the same message.
    # Therefore we bin them together into only 7 revisions.
    revisions.size.should eq(7)

    revisions[0].token.should eq("2005/07/15 11:53:30")
    revisions[0].committer_name.should eq("httpd")
    revisions[0].message.should eq("Initial data for the intelliglue project")

    revisions[1].token.should eq("2005/07/15 16:40:17")
    revisions[1].committer_name.should eq("pizzandre")
    revisions[1].message.should eq("*** empty log message ***")

    revisions[5].token.should eq("2005/07/26 20:35:13")
    revisions[5].committer_name.should eq("pizzandre")
    revisions[5].message.should eq("Issue number:\nObtained from:\nSubmitted by:\nReviewed by:\nAdding current milestones-")

    revisions[6].token.should eq("2005/07/26 20:39:16")
    revisions[6].committer_name.should eq("pizzandre")
    revisions[6].message.should eq("Issue number:\nObtained from:\nSubmitted by:\nReviewed by:\nCompleting and fixing milestones texts")
  end

  # A file is created and modified on the branch, then merged to the trunk, then deleted from the branch.
  # From the trunk"s point of view, we should see only the merge event.
  it "file_created_on_branch_as_seen_from_trunk" do
    revisions = CvsParser.parse File.read(DATA_DIR + "/file_created_on_branch.rlog"), { :branch_name => "HEAD" }
    revisions.size.should eq(1)
    revisions[0].message.should eq("merged new_file.rb from branch onto the HEAD")
  end

  # A file is created and modified on the branch, then merged to the trunk, then deleted from the branch.
  # From the branch"s point of view, we should see the add, modify, and delete only.
  it "file_created_on_branch_as_seen_from_branch" do
    revisions = CvsParser.parse File.read(DATA_DIR + "/file_created_on_branch.rlog"), { :branch_name => "my_branch" }
    revisions.size.should eq(3)
    revisions[0].message.should eq("added new_file.rb on the branch")
    revisions[1].message.should eq("modifed new_file.rb on the branch only")
    revisions[2].message.should eq("removed new_file.rb from the branch only")
  end

  # A file is created on the vender branch. This causes a simultaneous checkin on HEAD
  # with a different message ("Initial revision") but same committer_name name and timestamp.
  # We should only pick up one of these checkins.
  it "simultaneous_checkins" do
    revisions = CvsParser.parse File.read(DATA_DIR + "/simultaneous_checkins.rlog")
    revisions.size.should eq(1)
    revisions[0].message.should eq("Initial revision")
  end

  # Two different authors check in with two different messages at the exact same moment.
  # How this happens is a mystery, but I have seen it in rlogs.
  # We arbitrarily choose the first one if so.
  it "simultaneous_checkins_2" do
    revisions = CvsParser.parse File.read(DATA_DIR + "/simultaneous_checkins_2.rlog")
    revisions.size.should eq(1)
  end
end
