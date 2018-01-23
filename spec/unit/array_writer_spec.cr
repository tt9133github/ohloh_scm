require "../spec_helper"

describe "ArrayWriter" do

  it "basic" do
    # FIXME: ArrayWriter is not used
    # log = <<-LOG
    # ------------------------------------------------------------------------
    # r3 | robin | 2006-06-11 11:34:17 -0700 (Sun, 11 Jun 2006) | 1 line
    # Changed paths:
     # A /trunk/README
     # M /trunk/helloworld.c

    # added some documentation and licensing info
    # ------------------------------------------------------------------------
    # LOG

    # # By default, the ArrayWriter is used, and an empty string is parsed
    # SvnParser.parse.should eq(Array(Nil).new)
    # SvnParser.parse("").should eq(Array(Nil).new)
    # SvnParser.parse("", writer: ArrayWriter.new).should eq(Array(Nil).new)

    # result = SvnParser.parse(log, writer: ArrayWriter.new)
    # result.size.should eq(1)
    # result.first.committer_name.should eq("robin")
    # result.first.token.should eq(3)
    # result.first.diffs.size.should eq(2)
    # result.first.diffs.first.path.should eq("/trunk/README")
    # result.first.diffs.first.action.should eq("A")
  end
end
