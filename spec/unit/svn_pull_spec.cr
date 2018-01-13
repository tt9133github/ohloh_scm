require "../test_helper"
require "socket"

describe "SvnPull" do

  it "svnadmin_create" do
    OhlohScm::ScratchDir.new do |dir|
      url = File.join(dir, "my_svn_repo")
      svn = SvnAdapter.new({:url => url}).normalize

      svn.exist?.should be_falsey
      svn.svnadmin_create
      svn.exist?.should be_truthy

      # Ensure that revision properties are settable
      # Note that only valid properties can be set
      svn.propset("log","bar")
      svn.propget("log").should eq("bar")
    end
  end

  it "basic_pull_using_svnsync" do
    with_svn_repository("svn") do |src|
      OhlohScm::ScratchDir.new do |dest_dir|

        dest = SvnAdapter.new({:url => dest_dir}).normalize
        dest.exist?.should be_falsey

        dest.pull(src)
        dest.exist?.should be_truthy

        dest.log.should eq(src.log)
      end
    end
  end

  it "svnadmin_create_local" do
    OhlohScm::ScratchDir.new do |dir|
      svn = SvnAdapter.new({:url => "file://#{dir}"})
      svn.svnadmin_create_local
      svn.exist?.should be_truthy
      FileTest.exist?(File.join(dir, "hooks", "pre-revprop-change")).should be_truthy
      FileTest.executable?(File.join(dir, "hooks", "pre-revprop-change")).should be_truthy
      svn.run File.join(dir, "hooks", "pre-revprop-change")
    end
  end

  it "svnadmin_create_remote" do
    OhlohScm::ScratchDir.new do |dir|
      svn = SvnAdapter.new({:url => "svn+ssh://#{Socket.gethostname}#{dir}"})
      svn.svnadmin_create_remote
      svn.exist?.should be_truthy
      FileTest.exist?(File.join(dir, "hooks", "pre-revprop-change")).should be_truthy
      FileTest.executable?(File.join(dir, "hooks", "pre-revprop-change")).should be_truthy
      svn.run File.join(dir, "hooks", "pre-revprop-change")
    end
  end
end
