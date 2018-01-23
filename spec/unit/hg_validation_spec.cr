require "../spec_helper"

describe "HgValidation" do
  it "rejected_urls" do
    [ "", "foo", "http:/", "http:://", "http://", "http://a",
      "www.selenic.com/repo/hello", # missing a protool prefix
      "http://www.selenic.com/repo/hello%20world", # no encoded strings allowed
      "http://www.selenic.com/repo/hello world", # no spaces allowed
      "git://www.selenic.com/repo/hello", # git protocol not allowed
      "svn://www.selenic.com/repo/hello" # svn protocol not allowed
    ].each do |url|
      hg = HgAdapter.new(url: url, public_urls_only: true)
      hg.validate_url.as?(Array).should_not be_nil
    end
  end

  it "accepted_urls" do
    [ "http://www.selenic.com/repo/hello",
      "http://www.selenic.com:80/repo/hello",
      "https://www.selenic.com/repo/hello",
    ].each do |url|
      hg = HgAdapter.new(url: url, public_urls_only: true)
      hg.validate_url.should be_falsey
    end
  end

  # These urls are not available to the public
  it "rejected_public_urls" do
    [ "file:///home/robin/hg",
      "/home/robin/hg",
      "ssh://robin@localhost/home/robin/hg",
      "ssh://localhost/home/robin/hg"
    ].each do |url|
      hg = HgAdapter.new(url: url, public_urls_only: true)
      hg.validate_url.should be_truthy

      hg = HgAdapter.new(url: url)
      hg.validate_url.should be_falsey
    end
  end

  it "guess_forge" do
    hg = HgAdapter.new(url: "")
    hg.guess_forge.should eq(nil)

    hg = HgAdapter.new(url: "/home/robin/hg")
    hg.guess_forge.should eq(nil)

    hg = HgAdapter.new(url: "http://www.selenic.com/repo/hello")
    hg.guess_forge.should eq("www.selenic.com")

    hg = HgAdapter.new(url: "http://algoc.hg.sourceforge.net:8000/hgroot/algoc")
    hg.guess_forge.should eq("sourceforge.net")

    hg = HgAdapter.new(url: "http://poliqarp.sourceforge.net/hg/poliqarp/")
    hg.guess_forge.should eq("sourceforge.net")
  end
end
