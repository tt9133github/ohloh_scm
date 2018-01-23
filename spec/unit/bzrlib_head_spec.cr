require "../spec_helper"

describe "BzrlibHead" do

  it "head_and_parents" do
    with_bzrlib_repository("bzr") do |bzr|
      bzr.head_token.should eq("test@example.com-20111222183733-y91if5npo3pe8ifs")
      bzr.head.token.should eq("test@example.com-20111222183733-y91if5npo3pe8ifs")
      bzr.head.diffs.any?.should be_truthy # diffs should be populated

      bzr.parents(bzr.head).first.token.should eq("obnox@samba.org-20090204004942-73rnw0izen42f154")
      bzr.parents(bzr.head).first.diffs.any?.should be_truthy
    end
  end

end
