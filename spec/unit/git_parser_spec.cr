require "../spec_helper"

describe "GitParser" do

  it "empty_array" do
    GitParser.parse("").should eq(Array(Nil).new)
  end

  it "log_parser_default" do
sample_log = <<SAMPLE
commit 1df547800dcd168e589bb9b26b4039bff3a7f7e4
Author: Jason Allen <jason@ohloh.net>
Date:   Fri, 14 Jul 2006 16:07:15 -0700

  moving COPYING

A  COPYING

commit 2e9366dd7a786fdb35f211fff1c8ea05c51968b1
Author: Robin Luckey <robin@ohloh.net>
Date:   Sun, 11 Jun 2006 11:34:17 -0700

  added some documentation and licensing info

M  README
D  helloworld.c
SAMPLE

    commits = GitParser.parse(sample_log)

    commits.should be_truthy
    commits.size.should eq(2)

    commits[0].token.should eq("1df547800dcd168e589bb9b26b4039bff3a7f7e4")
    commits[0].author_name.should eq("Jason Allen")
    commits[0].author_email.should eq("jason@ohloh.net")
    commits[0].message.should eq("moving COPYING")
    commits[0].author_date.should eq(Time.utc(2006,7,14,23,7,15))
    commits[0].diffs.size.should eq(1)

    commits[0].diffs[0].action.should eq("A")
    commits[0].diffs[0].path.should eq("COPYING")

    commits[1].token.should eq("2e9366dd7a786fdb35f211fff1c8ea05c51968b1")
    commits[1].author_name.should eq("Robin Luckey")
    commits[1].author_email.should eq("robin@ohloh.net")
    commits[1].message.should eq("added some documentation and licensing info") # Note \n at end of comment
    commits[1].author_date.should eq(Time.utc(2006,6,11,18,34,17))
    commits[1].diffs.size.should eq(2)

    commits[1].diffs[0].action.should eq("M")
    commits[1].diffs[0].path.should eq("README")
    commits[1].diffs[1].action.should eq("D")
    commits[1].diffs[1].path.should eq("helloworld.c")
  end

end
