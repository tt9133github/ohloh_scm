require "../test_helper"

describe "SvnChain" do

  it "chain" do
    with_svn_chain_repository("svn_with_branching", "/trunk") do |svn|
      chain = svn.chain
      chain.size.should eq(5)

      # In revision 1, the trunk is created.
      chain[0].branch_name.should eq("/trunk")
      chain[0].first_token.should eq(1)
      chain[0].final_token.should eq(2)

      # In revision 3, the trunk was deleted, but restored in revision 4.
      # This creates the first discontinuity, and the first link in the chain.
      chain[1].branch_name.should eq("/trunk")
      chain[1].first_token.should eq(4)
      chain[1].final_token.should eq(4)

      # In revision 5, the branch is created by copying the trunk from revision 4.
      chain[2].branch_name.should eq("/branches/development")
      chain[2].first_token.should eq(5)
      chain[2].final_token.should eq(7)

      # In revision 8, a new trunk is created by copying the branch.
      # The next final_token will be 9.
      chain[3].branch_name.should eq("/trunk")
      chain[3].first_token.should eq(8)
      chain[3].final_token.should eq(9)

      # In revision 11, trunk is reverted back to rev 9
      # This trunk still lives on, so its final_token is nil.
      chain[4].branch_name.should eq("/trunk")
      chain[4].first_token.should eq(11)
      chain[4].final_token.should be_nil
    end
  end

  it "parent_svn" do
    with_svn_chain_repository("svn_with_branching", "/trunk") do |svn|
      # The first chain is the copy commit from trunk:9 into rev 11.
      p0 = svn.parent_svn
      p0.final_token.should eq(9)

      # In this repository, /branches/development becomes
      # the /trunk in revision 8. So there should be a parent
      # will final_token 7.
      p1 = p0.parent_svn
      svn.root + "/branches/development".should eq(p1.url)
      "/branches/development".should eq(p1.branch_name)
      7.should eq(p1.final_token)

      # There"s another move at revision 5, in which /branch/development
      # is created by copying /trunk from revision 4.
      p2 = p1.parent_svn
      svn.root + "/trunk".should eq(p2.url)
      "/trunk".should eq(p2.branch_name)
      4.should eq(p2.final_token)
    end
  end

  it "parent_branch_name" do
    svn = OhlohScm::Adapters::SvnChainAdapter.new({:branch_name => "/trunk"})

    svn.parent_branch_name(OhlohScm::Diff.new({:action => "A", :path => "/trunk", :from_revision => 1, :from_path => "/branches/b"})).should eq("/branches/b")
  end

  it "next_revision_xml_valid_encoding" do
    with_invalid_encoded_svn_repository do |svn|
      svn.next_revision_xml(0).valid_encoding?.should eq(true)
    end
  end
end
