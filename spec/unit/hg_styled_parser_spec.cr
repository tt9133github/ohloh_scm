require "../spec_helper"

describe "HgStyledParser" do
  it "should parse commits correctly" do
    log = <<-LOG
    __BEGIN_COMMIT__
    changeset: 72fe74d643bdcb30b00da3b58796c50f221017d0
    user:      Robin Luckey <robinluckey@gmail.com>
    date:      1291770772.028800
    __BEGIN_COMMENT__
    Merge
    __END_COMMENT__
    __END_COMMIT__
    __BEGIN_COMMIT__
    changeset: 732345b1d5f4076498132fd4b965b1fec0108a50
    user:      Robin Luckey <robinluckey@gmail.com>
    date:      1291770716.028800
    __BEGIN_COMMENT__
    Main line: delete hello.c
    __END_COMMENT__
    __END_COMMIT__
    __BEGIN_COMMIT__
    changeset: 73e93f57224e3fd828cf014644db8eec5013cd6b
    user:      Robin Luckey <robinluckey@gmail.com>
    date:      1291769937.028800
    __BEGIN_COMMENT__
    Initial revision
    __END_COMMENT__
    __END_COMMIT__
    LOG

    commits = HgStyledParser.parse(log)
    commits.size.should eq(3)
    commits[0].committer_date.should eq(Time.new(2010,12,8,1,12,52))
    commits[0].committer_email.should eq("robinluckey@gmail.com")
    commits[1].message.should eq("Main line: delete hello.c")
    commits[2].token.should eq("73e93f57224e3fd828cf014644db8eec5013cd6b")
  end
end
