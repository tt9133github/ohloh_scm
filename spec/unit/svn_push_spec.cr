require "../test_helper"
require "socket"

describe "SvnPush" do

  it "basic_push_using_svnsync" do
    with_svn_repository("svn") do |src|
      OhlohScm::ScratchDir.new do |dest_dir|

        dest = SvnAdapter.new({:url => dest_dir}).normalize
        dest.exist?.should be_falsey

        src.push(dest)
        dest.exist?.should be_truthy

        dest.log.should eq(src.log)
      end
    end
  end

  # Triggers the "ssh" code path by using svn+ssh:// protocol instead of file:// protocol.
  # Simulates pushing to another server in our cluster.
  it "ssh_push_using_svnsync" do
    with_svn_repository("svn") do |src|
      OhlohScm::ScratchDir.new do |dest_dir|

        dest = SvnAdapter.new({:url => "svn+ssh://#{Socket.gethostname}#{File.expand_path(dest_dir)}"}).normalize
        dest.exist?.should be_falsey

        src.push(dest)
        dest.exist?.should be_truthy

        dest.log.should eq(src.log)
      end
    end
  end

end
