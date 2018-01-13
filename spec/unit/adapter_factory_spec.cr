require "../test_helper"

describe "Factory" do

  it "factory_hg" do
    OhlohScm::ScratchDir.new do |path|
      `cd #{path} && hg init`
      hg = Factory.from_path(path)
      hg.is_a?(HgAdapter).should be_truthy
      path.should eq(hg.url)
    end
  end

  it "factory_bzr" do
    OhlohScm::ScratchDir.new do |path|
      `cd #{path} && bzr init`
      bzr = Factory.from_path(path)
      bzr.is_a?(BzrAdapter).should be_truthy
      path.should eq(bzr.url)
    end
  end

  it "factory_git" do
    OhlohScm::ScratchDir.new do |path|
      `cd #{path} && git init`
      git = Factory.from_path(path)
      git.is_a?(GitAdapter).should be_truthy
      path.should eq(git.url)
    end
  end

  it "factory_svn" do
    OhlohScm::ScratchDir.new do |path|
      `cd #{path} && svnadmin create foo`
      svn = Factory.from_path(File.join(path, "foo"))
      svn.is_a?(SvnAdapter).should be_truthy
      svn.url.should eq("file://" + File.expand_path(File.join(path, "foo")))
    end
  end

  it "factory_svn_checkout" do
    OhlohScm::ScratchDir.new do |path|
      `cd #{path} && svnadmin create foo`
      `cd #{path} && svn co file://#{File.expand_path(File.join(path, "foo"))} bar`
      svn = Factory.from_path(File.join(path, "bar"))
      svn.is_a?(SvnAdapter).should be_truthy
      # Note that even though we gave checkout dir "bar" to the factory,
      # we get back a link to the original repo at "foo"
      svn.url.should eq("file://" + File.expand_path(File.join(path, "foo")))
    end
  end

  it "factory_from_cvs_checkout" do
    with_cvs_repository("cvs", "simple") do |cvs|
      OhlohScm::ScratchDir.new do |path|
        `cd #{path} && cvsnt -d #{File.expand_path(cvs.url)} co simple 2> /dev/null`
        factory_response = Factory.from_path(File.join(path, "simple"))
        factory_response.is_a?(CvsAdapter).should be_truthy
        factory_response.url.should eq(cvs.url)
      end
    end
  end

end
