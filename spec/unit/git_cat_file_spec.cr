require "../test_helper"

describe "GitCatFile" do

  it "cat_file" do
    with_git_repository("git") do |git|
expected = <<-EXPECTED
/* Hello, World! */
#include <stdio.h>
main()
{
printf("Hello, World!\\n");
}
EXPECTED
      assert_equal expected, git.cat_file(nil, OhlohScm::Diff.new(:sha1 => "4c734ad53b272c9b3d719f214372ac497ff6c068"))
    end
  end

end
