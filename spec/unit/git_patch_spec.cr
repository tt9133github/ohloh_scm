require "../spec_helper"

describe "GitPatch" do
  it "patch_for_commit" do
    with_git_repository("git") do |repo|
      commit = repo.verbose_commit("b6e9220c3cabe53a4ed7f32952aeaeb8a822603d")
      data = File.read(File.join(DATA_DIR, "git_patch.diff"))
      repo.patch_for_commit(commit).should eq(data)
    end
  end
end
end
