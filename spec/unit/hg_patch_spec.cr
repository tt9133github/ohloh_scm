require "../test_helper"

describe "HgPatch" do
  it "patch_for_commit" do
    with_hg_repository("hg") do |repo|
      commit = repo.verbose_commit(1)
      data = File.read(File.join(DATA_DIR, "hg_patch.diff"))
      repo.patch_for_commit(commit).should eq(data)
    end
  end
end
