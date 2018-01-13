require "../test_helper"

describe "BzrPull" do

  it "pull" do
    with_bzr_repository("bzr") do |src|
      OhlohScm::ScratchDir.new do |dest_dir|

        dest = BzrAdapter.new(:url => dest_dir).normalize
        dest.exist?.should be_falsey

        dest.pull(src)
        dest.exist?.should be_truthy

        dest.log.should eq(src.log)

        # Commit some new code on the original and pull again
        src.run "cd "#{src.url}" && touch foo && bzr add foo && bzr whoami "test <test@example.com>" && bzr commit -m test"
        src.commits.last.message.should eq("test")
        src.commits.last.committer_name.should eq("test")
        src.commits.last.committer_email.should eq("test@example.com")

        dest.pull(src)
        dest.log.should eq(src.log)
      end
    end
  end

end
