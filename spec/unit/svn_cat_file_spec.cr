require "../spec_helper"

describe "SvnCatFile" do

  it "cat_file" do
    with_svn_repository("svn") do |svn|
expected = <<-EXPECTED
/* Hello, World! */
#include <stdio.h>
main()
{
	printf("Hello, World!\\n");
}

EXPECTED
      svn.cat_file(OhlohScm::Commit.new(token: "1"), OhlohScm::Diff.new(path: "trunk/helloworld.c")).should eq(expected)

      svn.cat_file(OhlohScm::Commit.new(token: "1"), OhlohScm::Diff.new(path: "file not found")).should be_nil
    end
  end
end
