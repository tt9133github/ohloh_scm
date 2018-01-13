# encoding: utf-8
require "../test_helper"

describe "BzrMisc" do

  it "exist" do
    save_bzr = nil
    with_bzr_repository("bzr") do |bzr|
      save_bzr = bzr
      save_bzr.exist?.should be_truthy
    end
    save_bzr.exist?.should be_falsey
  end

  it "ls_tree" do
    with_bzr_repository("bzr") do |bzr|
      bzr.ls_tree(bzr.head_token).sort.map { |filename| filename.force_encoding(Encoding::UTF_8) }.should eq(
        ["Cédric.txt", "file1.txt", "file3.txt", "file4.txt", "file5.txt"])
    end
  end

  it "export" do
    with_bzr_repository("bzr") do |bzr|
      OhlohScm::ScratchDir.new do |dir|
        bzr.export(dir)
        Dir.entries(dir).sort.should eq([".", "..", "Cédric.txt", "file1.txt", "file3.txt", "file4.txt", "file5.txt"])
      end
    end
  end

  it "tags" do
    with_bzr_repository("bzr") do |bzr|
      time_1 = Time.parse("2009-02-04 00:25:40 +0000")
      time_2 = Time.parse("2011-12-22 18:37:33 +0000")
      monkey_patch_run_method_to_match_tag_patterns
      bzr.tags.should eq([["v1.0.0", "5", time_1], ["v2.0.0","7", time_2]])
    end
  end

  private def monkey_patch_run_method_to_match_tag_patterns
    original_method = AbstractAdapter.method(:run)
    AbstractAdapter.send :define_method, :run do |command|
      if command =~ /bzr tags/
        # The output of `bzr tags` sometimes has tags referring to ? while sometimes has dotted separators.
        "0.11-1.1             ?\n0.14-1               ?\n....\n#{ original_method.call(command) }"
      else
        original_method.call(command)
      end
    end
  end
end
