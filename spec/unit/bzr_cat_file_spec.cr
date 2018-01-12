# encoding: utf-8
require "../test_helper"

describe "BzrCatFile" do

  it "cat_file" do
    with_bzr_repository("bzr") do |bzr|
      expected = <<-EXPECTED
first file
second line
EXPECTED
      assert_equal expected,
        bzr.cat_file(OhlohScm::Commit::new(:token => 6),
               OhlohScm::Diff.new(:path => "file1.txt"))

      # file2.txt has been removed in commit #5
      assert_equal nil, bzr.cat_file(bzr.head,
                   OhlohScm::Diff.new(:path => "file2.txt"))
    end
  end

  it "cat_file_non_ascii_name" do
    with_bzr_repository("bzr") do |bzr|
      expected = <<-EXPECTED
first file
second line
EXPECTED
      assert_equal expected,
        bzr.cat_file(OhlohScm::Commit::new(:token => 7),
               OhlohScm::Diff.new(:path => "Cédric.txt"))
    end
  end

  it "cat_file_parent" do
    with_bzr_repository("bzr") do |bzr|
      expected = <<-EXPECTED
first file
second line
EXPECTED
      assert_equal expected,
        bzr.cat_file_parent(OhlohScm::Commit::new(:token => 6),
                OhlohScm::Diff.new(:path => "file1.txt"))

      # file2.txt has been removed in commit #5
      expected = <<-EXPECTED
another file
EXPECTED
      assert_equal expected,
        bzr.cat_file_parent(OhlohScm::Commit.new(:token => 5),
                OhlohScm::Diff.new(:path => "file2.txt"))
    end
  end

end
