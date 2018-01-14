require "../spec_helper"

describe "BzrValidation" do
  it "rejected_urls" do
    [	nil, "", "foo", "http:/", "http:://", "http://", "http://a",
      "www.selenic.com/repo/hello", # missing a protool prefix
      "http://www.selenic.com/repo/hello%20world", # no encoded strings allowed
      "http://www.selenic.com/repo/hello world", # no spaces allowed
      "git://www.selenic.com/repo/hello", # git protocol not allowed
      "svn://www.selenic.com/repo/hello", # svn protocol not allowed
      "lp://foobar", # lp requires no "//" after colon
    ].each do |url|
      bzr = BzrAdapter.new({:url => url, :public_urls_only => true})
      bzr.validate_url.to_a.any?, "Didn't expect #{ url } to validate".should be_truthy
    end
  end

  it "accepted_urls" do
    [ "http://www.selenic.com/repo/hello",
      "http://www.selenic.com:80/repo/hello",
      "https://www.selenic.com/repo/hello",
      "bzr://www.selenic.com/repo/hello",
      "lp:foobar",
      "lp:~foobar/bar",
    ].each do |url|
      bzr = BzrAdapter.new({:url => url, :public_urls_only => true})
      bzr.validate_url.should be_falsey
    end
  end

  # These urls are not available to the public
  it "rejected_public_urls" do
    [ "file:///home/test/bzr",
      "/home/test/bzr",
      "bzr+ssh://test@localhost/home/test/bzr",
      "bzr+ssh://localhost/home/test/bzr"
    ].each do |url|
      bzr = BzrAdapter.new({:url => url, :public_urls_only => true})
      bzr.validate_url.should be_truthy

      bzr = BzrAdapter.new({:url => url})
      bzr.validate_url.should be_falsey
    end
  end

  it "guess_forge" do
    bzr = BzrAdapter.new({:url => nil})
    bzr.guess_forge.should eq(nil)

    bzr = BzrAdapter.new({:url => "/home/test/bzr"})
    bzr.guess_forge.should eq(nil)

    bzr = BzrAdapter.new({ :url => "bzr://www.selenic.com/repo/hello"})
    bzr.guess_forge.should eq("www.selenic.com")

    bzr = BzrAdapter.new({ :url => "http://www.selenic.com/repo/hello"})
    bzr.guess_forge.should eq("www.selenic.com")
  end
end
