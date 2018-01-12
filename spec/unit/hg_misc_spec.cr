require "../test_helper"

describe "HgMisc" do

  it "exist" do
    save_hg = nil
    with_hg_repository("hg") do |hg|
      save_hg = hg
      assert save_hg.exist?
    end
    assert !save_hg.exist?
  end

  it "ls_tree" do
    with_hg_repository("hg") do |hg|
      assert_equal ["README","makefile", "two"], hg.ls_tree(hg.head_token).sort
    end
  end

  it "export" do
    with_hg_repository("hg") do |hg|
      OhlohScm::ScratchDir.new do |dir|
        hg.export(dir)
        assert_equal [".", "..", "README", "makefile", "two"], Dir.entries(dir).sort
      end
    end
  end

  it "ls_tree_encoding" do
    with_hg_repository("hg_with_invalid_encoding") do |hg|
      filenames = hg.ls_tree("51ea5277ca27")

      filenames.each do |filename|
        assert_equal true, filename.valid_encoding?
      end
    end
  end

  it "tags" do
    with_hg_repository("hg") do |hg|
      time = Time.parse("Fri Jul 22 18:00:18 2016 +0530")
      assert_equal  [["tip", "5", time]], hg.tags
    end
  end
end