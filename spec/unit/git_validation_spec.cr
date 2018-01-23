require "../spec_helper"

describe "GitValidation" do
  it "rejected_urls" do
    ["", "foo", "http:/", "http:://", "http://", "http://a",
    "kernel.org/linux/linux.git", # missing a protocol prefix
    "http://kernel.org/linux/lin%32ux.git", # no encoded strings allowed
    "http://kernel.org/linux/linux.git malicious code", # no spaces allowed
    "svn://svn.mythtv.org/svn/trunk", # svn protocol is not allowed
    "/home/robin/cvs", # local file paths not allowed
    "file:///home/robin/cvs", # file protocol is not allowed
    ":pserver:anonymous:@juicereceiver.cvs.sourceforge.net:/cvsroot/juicereceiver" # pserver is just wrong
    ].each do |url|
      git = GitAdapter.new(url: url)
      git.validate_url.as?(Array).should_not be_nil
    end
  end

  it "accepted_urls" do
    [ "http://kernel.org/pub/scm/git/git.git",
    "git://kernel.org/pub/scm/git/git.git",
    "https://kernel.org/pub/scm/git/git.git",
    "https://kernel.org:8080/pub/scm/git/git.git",
    "git://kernel.org/~foo/git.git",
    "http://git.onerussian.com/pub/deb/impose+.git",
    "https://Person@github.com/Person/some_repo.git",
    "http://Person@github.com/Person/some_repo.git",
    "https://github.com/Person/some_repo",
    "http://github.com/Person/some_repo"
    ].each do |url|
      git = GitAdapter.new(url: url)
      git.validate_url.should be_falsey
    end
  end

  it "guess_forge" do
    git = GitAdapter.new(url: "")
    git.guess_forge.should eq(nil)

    git = GitAdapter.new(url: "git://methabot.git.sourceforge.net/gitroot/methabot")
    git.guess_forge.should eq("sourceforge.net")

    git = GitAdapter.new(url: "http://kernel.org/pub/scm/linux/kernel/git/stable/linux-2.6.17.y.git")
    git.guess_forge.should eq("kernel.org")
  end

  it "normalize_url" do
    GitAdapter.new(url: "").normalize_url.should eq("")
    GitAdapter.new(url: "foo").normalize_url.should eq("foo")

    # A non-Github URL: no change
    GitAdapter.new(url: "git://kernel.org/pub/scm/git/git.git").normalize_url.should eq("git://kernel.org/pub/scm/git/git.git")

    # A Github read-write URL: converted to read-only
    GitAdapter.new(url: "https://robinluckey@github.com/robinluckey/ohcount.git").normalize_url.should eq(
      "git://github.com/robinluckey/ohcount.git")

    # A Github read-write URL: converted to read-only
    GitAdapter.new(url: "git@github.com:robinluckey/ohcount.git").normalize_url.should eq(
      "git://github.com/robinluckey/ohcount.git")

    # A Github read-only URL: no change
    GitAdapter.new(url: "git@github.com:robinluckey/ohcount.git").normalize_url.should eq(
      "git://github.com/robinluckey/ohcount.git")
  end

  it "normalize_converts_to_read_only" do
    normalize_url_test("https://robinluckey@github.com/robinluckey/ohcount.git", "git://github.com/robinluckey/ohcount.git")
  end

  it "normalize_handles_https_with_user_at_github_format" do
    normalize_url_test("http://Person@github.com/Person/something.git", "git://github.com/Person/something.git")
  end

  it "normalize_handles_https_web_url" do
    normalize_url_test("https://github.com/Person/something", "git://github.com/Person/something")
  end

  it "normalize_handles_http_web_url" do
    normalize_url_test("http://github.com/Person/something", "git://github.com/Person/something")
  end
end

def normalize_url_test(url, result_url)
  git = GitAdapter.new(url: url)
  git.normalize
  git.url.should eq(result_url)
 end
