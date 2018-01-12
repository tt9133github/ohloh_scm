require "../test_helper"

describe "HgPatch" do
  it "patch_for_commit" do
    with_hg_repository("hg") do |repo|
      commit = repo.verbose_commit(1)
      data = File.read(File.join(DATA_DIR, "hg_patch.diff"))
      assert_equal data, repo.patch_for_commit(commit)
    end
  end
end
