require "../spec_helper"

describe "SvnConvert" do
  it "basic_convert" do
    with_svn_repository("svn") do |src|
      OhlohScm::ScratchDir.new do |dest_dir|
        dest = GitAdapter.new({:url => dest_dir}).normalize
        dest.exist?.should be_falsey

        dest.pull(src)
        dest.exist?.should be_truthy

        dest_commits = dest.commits
        src.commits.each_with_index do |c, i|
          # Because Subversion does not track authors (only committers),
          # the Subversion committer becomes the Git author.
          dest_commits[i].author_name.should eq(c.committer_name)
          dest_commits[i].author_date.should eq(c.committer_date.round)

          # The svn-to-git conversion process loses the trailing \n for single-line messages
          dest_commits[i].message.strip.should eq(c.message.strip)
        end
      end
    end
  end
end
