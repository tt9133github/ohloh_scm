require "../test_helper"

describe "HgHead" do

  it "head_and_parents" do
    with_hglib_repository("hg") do |hg|
      assert_equal "655f04cf6ad708ab58c7b941672dce09dd369a18", hg.head_token
      assert_equal "655f04cf6ad708ab58c7b941672dce09dd369a18", hg.head.token
      assert hg.head.diffs.any? # diffs should be populated

      assert_equal "75532c1e1f1de55c2271f6fd29d98efbe35397c4", hg.parents(hg.head).first.token
      assert hg.parents(hg.head).first.diffs.any?
    end
  end

end
