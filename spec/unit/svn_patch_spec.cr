require "../spec_helper"

describe "SvnPatch" do
  it "patch_for_commit" do
    with_svn_repository("svn") do |repo|
      commit = repo.verbose_commit(2)
      data = File.read(File.join(DATA_DIR, "svn_patch.diff"))
      repo.patch_for_commit(commit).should eq(data)
    end
  end
end
