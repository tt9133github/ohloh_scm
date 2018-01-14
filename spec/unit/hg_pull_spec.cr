require "../spec_helper"

describe "HgPull" do

  it "pull" do
    with_hg_repository("hg") do |src|
      OhlohScm::ScratchDir.new do |dest_dir|

        dest = HgAdapter.new({:url => dest_dir}).normalize
        dest.exist?.should be_falsey

        dest.pull(src)
        dest.exist?.should be_truthy

        dest.log.should eq(src.log)

        # Commit some new code on the original and pull again
        src.run "cd '#{src.url}' && touch foo && hg add foo && hg commit -u test -m test"
        src.commits.last.message.should eq("test\n")

        dest.pull(src)
        dest.log.should eq(src.log)
      end
    end
  end

end
