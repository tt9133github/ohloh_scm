require "../test_helper"

describe "CvsValidation" do
  it "rejected_urls" do
    [	nil, "", "foo", "http:/", "http:://", "http://", "http://a",
      ":pserver", # that's not enough
      ":pserver:anonymous", #still not enough
      ":pserver:anonymous:@ipodder.cvs.sourceforge.net", # missing the path
      ":pserver:anonymous:::@ipodder.cvs.sourceforge.net:/cvsroot/ipodder", # too many colons
      ":pserver@ipodder.cvs.sourceforge.net:/cvsroot/ipodder", # not enough colons
      ":pserver:anonymous:@ipodder.cvs.sourceforge.net/cvsroot/ipodder", # hostname and path not separated by colon
      ":pserver:anonymous:@ipodder.cvs.source/forge.net:/cvsroot/ipodder", # slash in hostname
      ":pserver:anonymous:ipodder.cvs.sourceforge.net:/cvsroot/ipodder", # missing @
      ":pserver:anonymous:@ipodder.cvs.sourceforge.net:cvsroot/ipodder", # path does not begin at root
      ":pserver:anonymous:@ipodder.cvs.sourceforge.net:/cvsr%23oot/ipodder", # no encoded chars allowed
      ":pserver:anonymous:@ipodder.cvs.sourceforge.net:/cvsroot/ipodder;asdf", # no ; in url
      ":pserver:anonymous:@ipodder.cvs.sourceforge.net:/cvsroot/ipodder malicious code", # spaces not allowed
      "sourceforge.net/svn/project/trunk", # missing a protocol prefix
      "file:///home/robin/cvs", # file protocol is not allowed
      "http://svn.sourceforge.net", # http protocol is not allowed
      "git://kernel.org/whatever/linux.git", # git protocol is not allowed
      "ext@kernel.org/whatever/linux.git" # ext protocol allowed, but starts with ":"
    ].each do |url|
      # Rejected for both internal and public use
      [true, false].each do |p|
        cvs = CvsAdapter.new({:url => url, :public_urls_only => p})
        cvs.validate_url.should be_truthy
      end
    end
  end

  it "accepted_urls" do
    [	":pserver:anonymous:@ipodder.cvs.sourceforge.net:/cvsroot/ipodder",
      ":pserver:anonymous@cvs-mirror.mozilla.org:/cvsroot",
      ":pserver:anonymous:@cvs-mirror.mozilla.org:/cvsroot",
      ":pserver:guest:@cvs.dev.java.net:/shared/data/ccvs/repository",
      ":pserver:anoncvs:password@anoncvs.postgresql.org:/projects/cvsroot",
      ":pserver:anonymous:@rubyeclipse.cvs.sourceforge.net:/cvsroot/rubyeclipse",
      ":pserver:cvs:cvs@cvs.winehq.org:/home/wine",
      ":pserver:tcpdump:anoncvs@cvs.tcpdump.org:/tcpdump/master",
      ":pserver:anonymous:@user-mode-linux.cvs.sourceforge.net:/cvsroot/user-mode-linux",
      ":pserver:anonymous:@sc2.cvs.sourceforge.net:/cvsroot/sc2",
      ":pserver:cool-dev:@sc2.cvs.sourceforge.net:/cvsroot/sc2", # Hyphen should be OK in username
      ":pserver:cvs_anon:@cvs.scms.waikato.ac.nz:/usr/local/global-cvs/ml_cvs", # Underscores should be ok in path
      ":pserver:anonymous:freefem++@idared.ann.jussieu.fr:/Users/pubcvs/cvs", # Pluses should be OK
      ":ext:anoncvs@opensource.conformal.com:/anoncvs/scrotwm" # scrotwm is a real life example
    ].each do |url|
      # Valid for both internal and public use
      [true, false].each do |p|
        cvs = CvsAdapter.new({:url => url, :public_urls_only => p})
        cvs.validate_url.should be_falsey
      end
    end
  end

  # Local files not accepted for public URLs
  it "local_file_url" do
    cvs = CvsAdapter.new({:url => "/root"})
    cvs.validate_url.should be_falsey

    cvs = CvsAdapter.new({:url => "/root", :public_urls_only => true})
    cvs.validate_url.should be_truthy
  end

  it "rejected_module_names" do
    [nil,"","%",";","&","\n","\t"].each do |x|
      cvs = CvsAdapter.new({:url => ":pserver:cvs:cvs@cvs.test.org:/test", :module_name => x})
      cvs.valid?.should be_falsey
      cvs.errors.first[0] = :module_name.should be_truthy
    end
  end

  it "accepted_module_names" do
    ["myproject","my/project","my/project/2.0","my_project","0","My .Net Module", "my-module", "my-module++"].each do |x|
      cvs = CvsAdapter.new({:url => ":pserver:cvs:cvs@cvs.test.org:/test", :module_name => x})
      cvs.valid?.should be_truthy
    end
  end

  it "symlink_fixup" do
    cvs = CvsAdapter.new({:url => ":pserver:anoncvs:@cvs.netbeans.org:/cvs"})
    cvs.normalize.url.should eq(":pserver:anoncvs:@cvs.netbeans.org:/shared/data/ccvs/repository")

    cvs = CvsAdapter.new({:url => ":pserver:anoncvs:@cvs.netbeans.org:/cvs/"})
    cvs.normalize.url.should eq(":pserver:anoncvs:@cvs.netbeans.org:/shared/data/ccvs/repository")

    cvs = CvsAdapter.new({:url => ":pserver:anoncvs:@cvs.dev.java.net:/cvs"})
    cvs.normalize.url.should eq(":pserver:anoncvs:@cvs.dev.java.net:/shared/data/ccvs/repository")

    cvs = CvsAdapter.new({:url => ":PSERVER:ANONCVS:@CVS.DEV.JAVA.NET:/cvs"})
    cvs.normalize.url.should eq(":PSERVER:ANONCVS:@CVS.DEV.JAVA.NET:/shared/data/ccvs/repository")

    cvs = CvsAdapter.new({:url => ":pserver:anonymous:@cvs.gna.org:/cvs/eagleusb"})
    cvs.normalize.url.should eq(":pserver:anonymous:@cvs.gna.org:/var/cvs/eagleusb")
  end

  it "sync_pserver_username_password" do
    # Pull username only from url
    cvs = CvsAdapter.new({:url => ":pserver:guest:@ohloh.net:/test"})
    cvs.normalize
    cvs.url.should eq(":pserver:guest:@ohloh.net:/test")
    cvs.username.should eq("guest")
    cvs.password.should eq("")

    # Pull username and password from url
    cvs = CvsAdapter.new({:url => ":pserver:guest:secret@ohloh.net:/test"})
    cvs.normalize
    cvs.url.should eq(":pserver:guest:secret@ohloh.net:/test")
    cvs.username.should eq("guest")
    cvs.password.should eq("secret")

    # Apply username and password to url
    cvs = CvsAdapter.new({:url => ":pserver::@ohloh.net:/test", :username => "guest", :password => "secret"})
    cvs.normalize
    cvs.url.should eq(":pserver:guest:secret@ohloh.net:/test")
    cvs.username.should eq("guest")
    cvs.password.should eq("secret")

    # Passwords disagree, use :password attribute
    cvs = CvsAdapter.new({:url => ":pserver:guest:old@ohloh.net:/test", :username => "guest", :password => "new"})
    cvs.normalize
    cvs.url.should eq(":pserver:guest:new@ohloh.net:/test")
    cvs.username.should eq("guest")
    cvs.password.should eq("new")
  end

  it "guess_forge" do
    cvs = CvsAdapter.new({:url => nil})
    cvs.guess_forge.should eq(nil)

    cvs = CvsAdapter.new({:url => "garbage_in_garbage_out"})
    cvs.guess_forge.should eq(nil)

    cvs = CvsAdapter.new({:url => ":pserver:anonymous:@boost.cvs.sourceforge.net:/cvsroot/boost"})
    cvs.guess_forge.should eq("sourceforge.net")

    cvs = CvsAdapter.new({:url => ":pserver:guest:@cvs.dev.java.net:/cvs"})
    cvs.guess_forge.should eq("java.net")

    cvs = CvsAdapter.new({:url => ":PSERVER:ANONCVS:@CVS.DEV.JAVA.NET:/cvs"})
    cvs.guess_forge.should eq("java.net")

    cvs = CvsAdapter.new({:url => ":pserver:guest:@colorchooser.dev.java.net:/cvs"})
    cvs.guess_forge.should eq("java.net")
  end
end
