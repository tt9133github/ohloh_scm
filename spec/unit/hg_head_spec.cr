require "../test_helper"

describe "HgHead" do

  it "hg_head_and_parents" do
    with_hg_repository("hg") do |hg|
      hg.head_token.should eq("655f04cf6ad708ab58c7b941672dce09dd369a18")
      hg.head.token.should eq("655f04cf6ad708ab58c7b941672dce09dd369a18")
      hg.head.diffs.any?.should be_truthy # diffs should be populated

      hg.parents(hg.head).first.token.should eq("75532c1e1f1de55c2271f6fd29d98efbe35397c4")
      hg.parents(hg.head).first.diffs.any?.should be_truthy
    end
  end

  it "head_with_branch" do
    with_hg_repository("hg", "develop") do |hg|
      hg.head.token.should eq("4d54c3f0526a1ec89214a70615a6b1c6129c665c")
      hg.head.diffs.any?.should be_truthy
    end
  end
end
