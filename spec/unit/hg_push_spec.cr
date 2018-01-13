require "../test_helper"

describe "HgPush" do

  it "hostname" do
    HgAdapter.new.hostname.should be_falsey
    HgAdapter.new(:url => "http://www.ohloh.net/test").hostname.should be_falsey
    HgAdapter.new(:url => "/Users/robin/foo").hostname.should be_falsey
    HgAdapter.new(:url => "ssh://foo/bar").hostname.should eq("foo")
  end

  it "local" do
    HgAdapter.new(:url => "foo:/bar").local?.should be_falsey # Assuming your machine is not named "foo" :-)
    HgAdapter.new(:url => "http://www.ohloh.net/foo").local?.should be_falsey
    HgAdapter.new(:url => "ssh://host/Users/robin/src").local?.should be_falsey
    HgAdapter.new(:url => "src").local?.should be_truthy
    HgAdapter.new(:url => "/Users/robin/src").local?.should be_truthy
    HgAdapter.new(:url => "file:///Users/robin/src").local?.should be_truthy
    HgAdapter.new(:url => "ssh://#{Socket.gethostname}/Users/robin/src").local?.should be_truthy
  end

  it "path" do
    HgAdapter.new().path.should eq(nil)
    HgAdapter.new(:url => "http://ohloh.net/foo").path.should eq(nil)
    HgAdapter.new(:url => "https://ohloh.net/foo").path.should eq(nil)
    HgAdapter.new(:url => "file:///Users/robin/foo").path.should eq("/Users/robin/foo")
    HgAdapter.new(:url => "ssh://localhost/Users/robin/foo").path.should eq("/Users/robin/foo")
    HgAdapter.new(:url => "/Users/robin/foo").path.should eq("/Users/robin/foo")
  end

  it "hg_path" do
    HgAdapter.new().hg_path.should eq(nil)
    HgAdapter.new(:url => "/Users/robin/src").hg_path.should eq("/Users/robin/src/.hg")
  end

  it "push" do
    with_hg_repository("hg") do |src|
      OhlohScm::ScratchDir.new do |dest_dir|

        dest = HgAdapter.new(:url => dest_dir).normalize
        dest.exist?.should be_falsey

        src.push(dest)
        dest.exist?.should be_truthy
        dest.log.should eq(src.log)

        # Commit some new code on the original and pull again
        src.run "cd '#{src.url}' && touch foo && hg add foo && hg commit -u test -m test"
        src.commits.last.message.should eq("test\n")

        src.push(dest)
        dest.log.should eq(src.log)
      end
    end
  end

end
