require 'spec_helper'

describe 'GitSvnStatus' do
  it 'should validate usernames' do
    [nil, '', 'joe_36', 'a' * 32, 'robin@ohloh.net'].each do |username|
      assert !get_base(username: username).status.send(:username_errors)
    end
  end

  it 'should validate rejected urls' do
    [nil, '', 'foo', 'http:/', 'http:://', 'http://',
     'sourceforge.net/svn/project/trunk', # missing a protocol prefix
     'http://robin@svn.sourceforge.net/', # must not include a username with the url
     '/home/robin/cvs', # local file paths not allowed
     'git://kernel.org/whatever/linux.git', # git protocol is not allowed
     ':pserver:anonymous:@juicereceiver.cvs.sourceforge.net:/cvsroot/juicereceiver', # pserver is just wrong
     'svn://svn.gajim.org:/gajim/trunk', # invalid port number
     'svn://svn.gajim.org:abc/gajim/trunk', # invalid port number
     'svn log https://svn.sourceforge.net/svnroot/myserver/trunk'].each do |url|
      # Rejected for both internal and public use
      assert get_base(url: url).status.send(:url_errors)
    end
  end

  it 'should validate urls' do
    [
      'https://svn.sourceforge.net/svnroot/opende/trunk', # https protocol OK
      'svn://svn.gajim.org/gajim/trunk', # svn protocol OK
      'http://svn.mythtv.org/svn/trunk/mythtv', # http protocol OK
      'https://svn.sourceforge.net/svnroot/vienna-rss/trunk/2.0.0', # periods, numbers and dashes OK
      'svn://svn.gajim.org:3690/gajim/trunk', # port number OK
      'http://svn.mythtv.org:80/svn/trunk/mythtv', # port number OK
      'http://svn.gnome.org/svn/gtk+/trunk', # + character OK
      'http://svn.gnome.org', # no path, no trailing /, just a domain name is OK
      'http://brlcad.svn.sourceforge.net/svnroot/brlcad/rt^3/trunk', # a caret ^ is allowed
      'http://www.thus.ch/~patrick/svn/pvalsecc', # ~ is allowed
      'http://franklinmath.googlecode.com/svn/trunk/Franklin Math' # space is allowed in path
    ].each do |url|
      # Accepted for both internal and public use
      assert !get_base(url: url).status.send(:url_errors)
    end
  end

  # These urls are not available to the public
  it 'should reject public urls' do
    ['file:///home/robin/svn'].each do |url|
      assert get_base(url: url).status.send(:url_errors)
    end
  end

  it 'should validate_server_connection' do
    save_svn = nil
    with_git_svn_repository('svn') do |svn|
      assert !svn.status.validate_server_connection # No errors
      save_svn = svn
    end
    save_svn.status.validate_server_connection.must_be_nil
  end

  it 'should strip trailing whitespace in branch_name' do
    get_base(branch_name: '/trunk/').scm.normalize.branch_name.must_equal '/trunk'
  end

  it 'should catch exception when validating server connection' do
    git_svn = get_base
    OhlohScm::GitSvnStatus.any_instance.stubs(:valid?).returns(true)
    git_svn.status.validate_server_connection
    msg = 'An error occured connecting to the server. Check the URL, username, and password.'
    git_svn.status.errors.must_equal [[:failed, msg]]
  end

  it 'should validate head token when validating server connection' do
    git_svn = get_base
    OhlohScm::GitSvnStatus.any_instance.stubs(:valid?).returns(true)
    OhlohScm::GitSvnActivity.any_instance.stubs(:head_token).returns(nil)
    git_svn.status.validate_server_connection
    msg = "The server did not respond to a 'svn info' command. Is the URL correct?"
    git_svn.status.errors.must_equal [[:failed, msg]]
  end

  it 'should validate url when validating server connection' do
    git_svn = get_base
    OhlohScm::GitSvnStatus.any_instance.stubs(:valid?).returns(true)
    OhlohScm::GitSvnActivity.any_instance.stubs(:head_token).returns('')
    OhlohScm::GitSvnActivity.any_instance.stubs(:root).returns('tt')
    git_svn.status.validate_server_connection
    git_svn.status.errors.must_equal [[:failed, 'The URL did not match the Subversion root tt. Is the URL correct?']]
  end

  def get_base(opts = {})
    OhlohScm::Factory.get_base({ scm_type: :git_svn, url: 'foo' }.merge(opts))
  end
end
