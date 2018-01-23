require "../spec_helper"

describe "Factory" do

  it "factory_hg" do
    OhlohScm::ScratchDir.new do |path|
      `cd #{path} && hg init`
      hg = Factory.from_path(path).as(HgAdapter)
      path.should eq(hg.url)
    end
  end

  it "factory_bzr" do
    OhlohScm::ScratchDir.new do |path|
      `cd #{path} && bzr init`
      bzr = Factory.from_path(path).as(BzrAdapter)
      path.should eq(bzr.url)
    end
  end

  it "factory_git" do
    OhlohScm::ScratchDir.new do |path|
      `cd #{path} && git init`
      git = Factory.from_path(path).as(GitAdapter)
      path.should eq(git.url)
    end
  end

  it "factory_svn" do
    OhlohScm::ScratchDir.new do |path|
      `cd #{path} && svnadmin create foo`
      svn = Factory.from_path(File.join(path, "foo")).as(SvnAdapter)
      svn.url.should eq("file://" + File.expand_path(File.join(path, "foo")))
    end
  end

  it "factory_svn_checkout" do
    OhlohScm::ScratchDir.new do |path|
      `cd #{path} && svnadmin create foo`
      `cd #{path} && svn co file://#{File.expand_path(File.join(path, "foo"))} bar`
      svn = Factory.from_path(File.join(path, "bar")).as(SvnAdapter)
      # Note that even though we gave checkout dir "bar" to the factory,
      # we get back a link to the original repo at "foo"
      svn.url.should eq("file://" + File.expand_path(File.join(path, "foo")))
    end
  end

  it "factory_from_cvs_checkout" do
    with_cvs_repository("cvs", "simple") do |cvs|
      OhlohScm::ScratchDir.new do |path|
        `cd #{path} && cvsnt -d #{File.expand_path(cvs.url)} co simple 2> /dev/null`
        factory_response = Factory.from_path(File.join(path, "simple")).as(CvsAdapter)
        factory_response.url.should eq(cvs.url)
      end
    end
  end

end
