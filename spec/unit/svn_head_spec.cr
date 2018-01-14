require "../spec_helper"

describe "SvnHead" do

  it "head_and_parents" do
    with_svn_repository("svn") do |svn|
      svn.head_token.should eq(5)
      svn.head.token.should eq(5)
      svn.head.diffs.any?.should be_truthy

      svn.parents(svn.head).first.token.should eq(4)
      svn.parents(svn.head).first.diffs.any?.should be_truthy
    end
  end

  it "parents_encoding" do
    with_invalid_encoded_svn_repository do |svn|
      commit = Struct.new(:token).new(:anything)
      svn.parents(commit) rescue raise Exception
    end
  end
end
end
