require "../spec_helper"

describe "HgParser" do

  it "empty_array" do
    HgParser.parse("").should eq(Array(Nil).new)
  end

  it "log_parser_default" do
sample_log = <<SAMPLE
changeset:   1:b14fa4692f94
user:        Jason Allen <jason@ohloh.net>
date:        Tue, Jan 20 2009 11:33:17 -0800
summary:     added makefile


changeset:   0:01101d8ef3ce
user:        Robin Luckey <robin@ohloh.net>
date:        Tue, Jan 20 2009 11:32:54 -0800
summary:     Initial Checkin

SAMPLE

    commits = HgParser.parse(sample_log)

    commits.should be_truthy
    commits.size.should eq(2)

    commits[0].token.should eq("b14fa4692f94")
    commits[0].committer_name.should eq("Jason Allen")
    commits[0].committer_email.should eq("jason@ohloh.net")
    commits[0].message.should eq("added makefile") # Note \n at end of comment
    commits[0].committer_date.should eq(Time.utc(2009,1,20,19,33,17))
    commits[0].diffs.size.should eq(0)

    commits[1].token.should eq("01101d8ef3ce")
    commits[1].committer_name.should eq("Robin Luckey")
    commits[1].committer_email.should eq("robin@ohloh.net")
    commits[1].message.should eq("Initial Checkin") # Note \n at end of comment
    commits[1].committer_date.should eq(Time.utc(2009,1,20,19,32,54))
    commits[1].diffs.size.should eq(0)
  end

  it "log_parser_default_partial_user_name" do
sample_log = <<SAMPLE
changeset:   259:45c293b71341
user:        robin@ohloh.net
date:        Sat, Jun 04 2005 23:37:11 -0800
summary:     fix addremove

SAMPLE

    commits = HgParser.parse(sample_log)

    commits.should be_truthy
    commits.size.should eq(1)

    commits[0].token.should eq("45c293b71341")
    commits[0].committer_name.should eq("robin@ohloh.net")
    commits[0].committer_email.should be_falsey
  end

  # Sometimes the log does not include a summary
  it "log_parser_default_no_summary" do
sample_log = <<SAMPLE
changeset:   1:b14fa4692f94
user:        Jason Allen <jason@ohloh.net>
date:        Tue, Jan 20 2009 11:33:17 -0800


changeset:   0:01101d8ef3ce
user:        Robin Luckey <robin@ohloh.net>
date:        Tue, Jan 20 2009 11:32:54 -0800

SAMPLE
    commits = HgParser.parse(sample_log)

    commits.should be_truthy
    commits.size.should eq(2)

    commits[0].token.should eq("b14fa4692f94")
    commits[0].committer_name.should eq("Jason Allen")
    commits[0].committer_email.should eq("jason@ohloh.net")
    commits[0].committer_date.should eq(Time.utc(2009,1,20,19,33,17))
    commits[0].diffs.size.should eq(0)

    commits[1].token.should eq("01101d8ef3ce")
    commits[1].committer_name.should eq("Robin Luckey")
    commits[1].committer_email.should eq("robin@ohloh.net")
    commits[1].committer_date.should eq(Time.utc(2009,1,20,19,32,54))
    commits[1].diffs.size.should eq(0)
  end

  it "log_parser_verbose" do
sample_log = <<SAMPLE
changeset:   1:b14fa4692f94
user:        Jason Allen <jason@ohloh.net>
date:        Tue, Jan 20 2009 11:33:17 -0800
files:       makefile
description:
added makefile


changeset:   0:01101d8ef3ce
user:        Robin Luckey <robin@ohloh.net>
date:        Tue, Jan 20 2009 11:32:54 -0800
files:       helloworld.c
description:
Initial Checkin


SAMPLE

    commits = HgParser.parse(sample_log)

    commits.should be_truthy
    commits.size.should eq(2)

    commits[0].token.should eq("b14fa4692f94")
    commits[0].committer_name.should eq("Jason Allen")
    commits[0].committer_email.should eq("jason@ohloh.net")
    commits[0].message.should eq("added makefile\n") # Note \n at end of comment
    commits[0].committer_date.should eq(Time.utc(2009,1,20,19,33,17))
    commits[0].diffs.size.should eq(1)
    commits[0].diffs[0].path.should eq("makefile")

    commits[1].token.should eq("01101d8ef3ce")
    commits[1].committer_name.should eq("Robin Luckey")
    commits[1].committer_email.should eq("robin@ohloh.net")
    commits[1].message.should eq("Initial Checkin\n") # Note \n at end of comment
    commits[1].committer_date.should eq(Time.utc(2009,1,20,19,32,54))
    commits[1].diffs.size.should eq(1)
    commits[1].diffs[0].path.should eq("helloworld.c")
  end

  it "styled_parser" do
    with_hg_repository("hg") do |hg|
      FileTest.exist?(HgStyledParser.style_path).should be_truthy
      log = hg.run("cd #{hg.url} && hg log -f --style #{OhlohScm::Parsers::HgStyledParser.style_path}")
      commits = OhlohScm::Parsers::HgStyledParser.parse(log)
      assert_styled_commits(commits, false)

      FileTest.exist?(HgStyledParser.verbose_style_path).should be_truthy
      log = hg.run("cd #{hg.url} && hg log -f --style #{OhlohScm::Parsers::HgStyledParser.verbose_style_path}")
      commits = OhlohScm::Parsers::HgStyledParser.parse(log)
      assert_styled_commits(commits, true)
    end
  end

  protected

  def assert_styled_commits(commits, with_diffs=false)
    commits.size.should eq(5)

    commits[1].token.should eq("75532c1e1f1de55c2271f6fd29d98efbe35397c4")
    commits[1].committer_name.should eq("Robin Luckey")
    commits[1].committer_email.should eq("robin@ohloh.net")
    Time.utc(2009,1,20,19,34,53) - commits[1].committer_date < 1.should be_truthy # Don"t care about milliseconds
    commits[1].message.should eq("deleted helloworld.c\n")

    if with_diffs
      commits[1].diffs.size.should eq(1)
      commits[1].diffs[0].action.should eq("D")
      commits[1].diffs[0].path.should eq("helloworld.c")
    else
      commits[1].diffs.should eq(Array(Nil).new)
    end

    commits[2].token.should eq("468336c6671cbc58237a259d1b7326866afc2817")
    Time.utc(2009, 1,20,19,34,04) - commits[2].committer_date < 1.should be_truthy

    if with_diffs
      commits[2].diffs.size.should eq(2)
      commits[2].diffs[0].action.should eq("M")
      commits[2].diffs[0].path.should eq("helloworld.c")
      commits[2].diffs[1].action.should eq("A")
      commits[2].diffs[1].path.should eq("README")
    else
      commits[0].diffs.should eq(Array(Nil).new)
    end
  end
end
