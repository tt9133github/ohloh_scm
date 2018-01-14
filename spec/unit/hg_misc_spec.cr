require "../spec_helper"

describe "HgMisc" do

  it "exist" do
    save_hg = nil
    with_hg_repository("hg") do |hg|
      save_hg = hg
      save_hg.exist?.should be_truthy
    end
    save_hg.exist?.should be_falsey
  end

  it "ls_tree" do
    with_hg_repository("hg") do |hg|
      hg.ls_tree(hg.head_token).sort.should eq(["README","makefile", "two"])
    end
  end

  it "export" do
    with_hg_repository("hg") do |hg|
      OhlohScm::ScratchDir.new do |dir|
        hg.export(dir)
        Dir.entries(dir).sort.should eq([".", "..", "README", "makefile", "two"])
      end
    end
  end

  it "ls_tree_encoding" do
    with_hg_repository("hg_with_invalid_encoding") do |hg|
      filenames = hg.ls_tree("51ea5277ca27")

      filenames.each do |filename|
        filename.valid_encoding?.should eq(true)
      end
    end
  end

  it "tags" do
    with_hg_repository("hg") do |hg|
      time = Time.parse("Fri Jul 22 18:00:18 2016 +0530")
      hg.tags.should eq([["tip", "5", time]])
    end
  end
end
