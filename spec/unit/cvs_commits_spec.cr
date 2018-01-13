require "../test_helper"

describe "CvsCommits" do

  it "commits" do
    with_cvs_repository("cvs", "simple") do |cvs|

      cvs.commits.map { |c| c.token }.should eq(["2006-06-29 16:21:07",
                                                 "2006-06-29 18:14:47",
                                                 "2006-06-29 18:45:29",
                                                 "2006-06-29 18:48:54",
                                                 "2006-06-29 18:52:23"])

      # Make sure we are date format agnostic (2008/01/01 is the same as 2008-01-01)
      cvs.commits({:after => "2006/06/29 18:45:29"}).map { |c| c.token }.should eq(
        ["2006-06-29 18:48:54", "2006-06-29 18:52:23"])

      cvs.commits({:after => "2006-06-29 18:45:29"}).map { |c| c.token }.should eq(
        ["2006-06-29 18:48:54", "2006-06-29 18:52:23"])

      cvs.commits({:after => "2006/06/29 18:52:23"}).map { |c| c.token }.should eq([])
    end
  end

  it "commits_sets_scm" do
    with_cvs_repository("cvs", "simple") do |cvs|
      cvs.commits.each do |c|
        c.scm.should eq(cvs)
      end
    end
  end

  it "open_log_file_encoding" do
    with_cvs_repository("cvs", "invalid_utf8") do |cvs|
      cvs.open_log_file do |io|
        io.read.valid_encoding?.should eq(true)
      end
    end
  end

  it "commits_valid_encoding" do
    with_cvs_repository("cvs", "invalid_utf8") do |cvs|
      cvs.commits
    end
  end
end
