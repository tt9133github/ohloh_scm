require "../test_helper"

describe "SvnValidation" do
  it "valid_usernames" do
    [nil,"","joe_36","a"*32,"robin@ohloh.net"].each do |username|
      assert !SvnAdapter.new(:username => username).validate_username
    end
  end

  it "for_blank_svn_urls" do
    svn = SvnAdapter.new(:url =>"")
    assert_nil svn.path_to_file_url(svn.url)
  end

  it "for_non_blank_svn_urls" do
    svn = SvnAdapter.new(:url =>"/home/rapbhan")
    assert_equal "file:///home/rapbhan", svn.path_to_file_url(svn.url)
  end

  it "rejected_urls" do
    [	nil, "", "foo", "http:/", "http:://", "http://",
    "sourceforge.net/svn/project/trunk", # missing a protocol prefix
    "http://robin@svn.sourceforge.net/", # must not include a username with the url
    "/home/robin/cvs", # local file paths not allowed
    "git://kernel.org/whatever/linux.git", # git protocol is not allowed
    ":pserver:anonymous:@juicereceiver.cvs.sourceforge.net:/cvsroot/juicereceiver", # pserver is just wrong
    "svn://svn.gajim.org:/gajim/trunk", # invalid port number
    "svn://svn.gajim.org:abc/gajim/trunk", # invalid port number
    "svn log https://svn.sourceforge.net/svnroot/myserver/trunk"
    ].each do |url|
      # Rejected for both internal and public use
      [true, false].each do |p|
        svn = SvnAdapter.new(:url => url, :public_urls_only => p)
        assert svn.validate_url
      end
    end
  end

  it "accepted_urls" do
    [	"https://svn.sourceforge.net/svnroot/opende/trunk", # https protocol OK
    "svn://svn.gajim.org/gajim/trunk", # svn protocol OK
    "http://svn.mythtv.org/svn/trunk/mythtv", # http protocol OK
    "https://svn.sourceforge.net/svnroot/vienna-rss/trunk/2.0.0", # periods, numbers and dashes OK
    "svn://svn.gajim.org:3690/gajim/trunk", # port number OK
    "http://svn.mythtv.org:80/svn/trunk/mythtv", # port number OK
    "http://svn.gnome.org/svn/gtk+/trunk", # + character OK
    "http://svn.gnome.org", # no path, no trailing /, just a domain name is OK
    "http://brlcad.svn.sourceforge.net/svnroot/brlcad/rt^3/trunk", # a caret ^ is allowed
    "http://www.thus.ch/~patrick/svn/pvalsecc", # ~ is allowed
    "http://franklinmath.googlecode.com/svn/trunk/Franklin Math", # space is allowed in path
    ].each do |url|
      # Accepted for both internal and public use
      [true, false].each do |p|
        svn = SvnAdapter.new(:url => url, :public_urls_only => p)
        assert !svn.validate_url
      end
    end
  end

  # These urls are not available to the public
  it "rejected_public_urls" do
    [ "file:///home/robin/svn"
    ].each do |url|
      svn = SvnAdapter.new(:url => url, :public_urls_only => true)
      assert svn.validate_url

      svn = SvnAdapter.new(:url => url)
      assert !svn.validate_url
    end
  end

  it "guess_forge" do
    svn = SvnAdapter.new(:url => nil)
    assert_equal nil, svn.guess_forge

    svn = SvnAdapter.new(:url => "garbage_in_garbage_out")
    assert_equal nil, svn.guess_forge

    svn = SvnAdapter.new(:url => "svn://rubyforge.org//var/svn/rubyomf2097")
    assert_equal "rubyforge.org", svn.guess_forge

    svn = SvnAdapter.new(:url => "svn://rubyforge.org:3960//var/svn/rubyomf2097")
    assert_equal "rubyforge.org", svn.guess_forge

    svn = SvnAdapter.new(:url => "http://bivouac.rubyforge.org/svn/trunk")
    assert_equal "rubyforge.org", svn.guess_forge

    svn = SvnAdapter.new(:url => "https://svn.sourceforge.net/svnroot/typo3/CoreDocs/trunk")
    assert_equal "sourceforge.net", svn.guess_forge

    svn = SvnAdapter.new(:url => "https://svn.sourceforge.net:80/svnroot/typo3/CoreDocs/trunk")
    assert_equal "sourceforge.net", svn.guess_forge

    svn = SvnAdapter.new(:url => "https://vegastrike.svn.sourceforge.net/svnroot/vegastrike/trunk")
    assert_equal "sourceforge.net", svn.guess_forge

    svn = SvnAdapter.new(:url => "https://svn.code.sf.net/p/gallery/code/trunk/gallery2")
    assert_equal "code.sf.net", svn.guess_forge

    svn = SvnAdapter.new(:url => "https://appfuse.dev.java.net/svn/appfuse/trunk")
    assert_equal "java.net", svn.guess_forge

    svn = SvnAdapter.new(:url => "http://moulinette.googlecode.com/svn/trunk")
    assert_equal "googlecode.com", svn.guess_forge

    svn = SvnAdapter.new(:url => "http://moulinette.googlecode.com")
    assert_equal "googlecode.com", svn.guess_forge
  end

  it "sourceforge_requires_https" do
    url = "://svn.code.sf.net/p/gallery/code/trunk/gallery2"
    assert_equal "https#{url}", SvnAdapter.new(:url => "http#{url}").normalize.url

    assert_equal "https#{url}", SvnAdapter.new(:url => "https#{url}").normalize.url

    url = "https://github.com/blackducksw/ohloh_scm/trunk"
    assert_equal url,  SvnAdapter.new(:url => url).normalize.url
  end

  it "validate_server_connection" do
    save_svn = nil
    with_svn_repository("svn") do |svn|
      assert !svn.validate_server_connection # No errors
      save_svn = svn
    end
    assert save_svn.validate_server_connection.any? # Repo is gone, should get an error
  end

  it "recalc_branch_name" do
    with_svn_repository("svn") do |svn|
      svn_based_at_root = SvnAdapter.new(:url => svn.root)
      assert !svn_based_at_root.branch_name
      assert_equal "", svn_based_at_root.recalc_branch_name
      assert_equal "", svn_based_at_root.branch_name

      svn_based_at_root_with_whack = SvnAdapter.new(:url => svn.root, :branch_name => "/")
      assert_equal "", svn_based_at_root.recalc_branch_name
      assert_equal "", svn_based_at_root.branch_name

      svn_trunk = SvnAdapter.new(:url => svn.root + "/trunk")
      assert !svn_trunk.branch_name
      assert_equal "/trunk", svn_trunk.recalc_branch_name
      assert_equal "/trunk", svn_trunk.branch_name

      svn_trunk_with_whack = SvnAdapter.new(:url => svn.root + "/trunk/")
      assert !svn_trunk_with_whack.branch_name
      assert_equal "/trunk", svn_trunk_with_whack.recalc_branch_name
      assert_equal "/trunk", svn_trunk_with_whack.branch_name

      svn_trunk = SvnAdapter.new(:url => svn.root + "/trunk")
      assert !svn_trunk.branch_name
      svn_trunk.normalize # only normalize to ensure branch_name is populated correctly
      assert_equal "/trunk", svn_trunk.branch_name

      svn_trunk = SvnAdapter.new(:url => svn.root)
      assert !svn_trunk.branch_name
      svn_trunk.normalize
      assert_equal "", svn_trunk.branch_name
    end
  end

  it "strip_trailing_whack_from_branch_name" do
    with_svn_repository("svn") do |svn|
      assert_equal "/trunk", SvnAdapter.new(:url => svn.root, :branch_name => "/trunk/").normalize.branch_name
    end
  end

  it "empty_branch_name_with_file_system" do
    OhlohScm::ScratchDir.new do |dir|
      svn = SvnAdapter.new(:url => dir).normalize
      assert_equal "", svn.branch_name
    end
  end
end
