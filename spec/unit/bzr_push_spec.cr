require "../test_helper"

describe "BzrPush" do

  it "hostname" do
    BzrAdapter.new.hostname.should be_falsey
    BzrAdapter.new(:url => "http://www.ohloh.net/test").hostname.should be_falsey
    BzrAdapter.new(:url => "/Users/test/foo").hostname.should be_falsey
    BzrAdapter.new(:url => "bzr+ssh://foo/bar").hostname.should eq("foo")
  end

  it "local" do
    BzrAdapter.new(:url => "foo:/bar").local?.should be_falsey # Assuming your machine is not named "foo" :-)
    BzrAdapter.new(:url => "http://www.ohloh.net/foo").local?.should be_falsey
    BzrAdapter.new(:url => "bzr+ssh://host/Users/test/src").local?.should be_falsey
    BzrAdapter.new(:url => "src").local?.should be_truthy
    BzrAdapter.new(:url => "/Users/test/src").local?.should be_truthy
    BzrAdapter.new(:url => "file:///Users/test/src").local?.should be_truthy
    BzrAdapter.new(:url => "bzr+ssh://#{Socket.gethostname}/Users/test/src").local?.should be_truthy
  end

  it "path" do
    BzrAdapter.new().path.should eq(nil)
    BzrAdapter.new(:url => "http://ohloh.net/foo").path.should eq(nil)
    BzrAdapter.new(:url => "https://ohloh.net/foo").path.should eq(nil)
    BzrAdapter.new(:url => "file:///Users/test/foo").path.should eq("/Users/test/foo")
    BzrAdapter.new(:url => "bzr+ssh://localhost/Users/test/foo").path.should eq("/Users/test/foo")
    BzrAdapter.new(:url => "/Users/test/foo").path.should eq("/Users/test/foo")
  end

  it "bzr_path" do
    BzrAdapter.new().bzr_path.should eq(nil)
    BzrAdapter.new(:url => "/Users/test/src").bzr_path.should eq("/Users/test/src/.bzr")
  end

  it "push" do
    with_bzr_repository("bzr") do |src|
      OhlohScm::ScratchDir.new do |dest_dir|

        dest = BzrAdapter.new(:url => dest_dir).normalize
        dest.exist?.should be_falsey

        src.push(dest)
        dest.exist?.should be_truthy
        dest.log.should eq(src.log)

        # Commit some new code on the original and pull again
        src.run "cd '#{src.url}' && touch foo && bzr add foo && bzr whoami 'test <test@example.com>' && bzr commit -m test"
        src.commits.last.message.should eq("test")
        src.commits.last.committer_name.should eq("test")
        src.commits.last.committer_email.should eq("test@example.com")

        src.push(dest)
        dest.log.should eq(src.log)
      end
    end
  end

end
