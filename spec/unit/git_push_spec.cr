require "../test_helper"

describe "GitPush" do

  it "hostname" do
    GitAdapter.new(:url => "foo:/bar").hostname.should eq("foo")
    GitAdapter.new(:url => "foo:/bar").path.should eq("/bar")

    GitAdapter.new.hostname.should be_falsey
    GitAdapter.new(:url => "/bar").hostname.should be_falsey
    GitAdapter.new(:url => "http://www.ohloh.net/bar").hostname.should eq("http")
  end

  it "local" do
    GitAdapter.new(:url => "foo:/bar").local?.should be_falsey # Assuming your machine is not named "foo" :-)
    GitAdapter.new(:url => "http://www.ohloh.net/foo").local?.should be_falsey
    GitAdapter.new(:url => "src").local?.should be_truthy
    GitAdapter.new(:url => "/Users/robin/src").local?.should be_truthy
    GitAdapter.new(:url => "#{`hostname`.strip}:src").local?.should be_truthy
    GitAdapter.new(:url => "#{`hostname`.strip}:/Users/robin/src").local?.should be_truthy
  end

  it "basic_push" do
    with_git_repository("git") do |src|
      OhlohScm::ScratchDir.new do |dest_dir|
        dest = GitAdapter.new(:url => dest_dir).normalize
        dest.exist?.should be_falsey

        src.push(dest)
        dest.exist?.should be_truthy
        dest.log.should eq(src.log)

        # Now push again. This tests a different code path!
        File.open(File.join(src.url, "foo"), "w") { }
        src.commit_all(OhlohScm::Commit.new)

        system("cd #{ dest_dir } && git config --bool core.bare true && git config receive.denyCurrentBranch refuse")
        src.push(dest)
        dest.exist?.should be_truthy
        dest.log.should eq(src.log)
      end
    end
  end
end
