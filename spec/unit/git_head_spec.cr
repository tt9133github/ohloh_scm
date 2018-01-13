require "../test_helper"

describe "GitHead" do

  it "head_and_parents" do
    with_git_repository("git") do |git|
      git.exist?.should be_truthy
      git.head_token.should eq("1df547800dcd168e589bb9b26b4039bff3a7f7e4")
      git.head.token.should eq("1df547800dcd168e589bb9b26b4039bff3a7f7e4")
      git.head.diffs.any?.should be_truthy

      git.parents(git.head).first.token.should eq("2e9366dd7a786fdb35f211fff1c8ea05c51968b1")
      git.parents(git.head).first.diffs.any?.should be_truthy
    end
  end

  it "head_token" do
    with_git_repository("git_with_invalid_encoding") do |git|
      git.head_token
    end
  end
end
