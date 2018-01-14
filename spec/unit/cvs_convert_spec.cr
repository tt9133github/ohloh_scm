require "../spec_helper"

describe "CvsConvert" do

  it "basic_convert" do
    with_cvs_repository("cvs", "simple") do |src|
      OhlohScm::ScratchDir.new do |dest_dir|
        dest = GitAdapter.new({:url => dest_dir}).normalize
        dest.exist?.should be_falsey

        dest.pull(src)
        dest.exist?.should be_truthy

        dest_commits = dest.commits
        src.commits.each_with_index do |c, i|
          # Because CVS does not track authors (only committers),
          # the CVS committer becomes the Git author.
          dest_commits[i].author_date.should eq(c.committer_date)
          dest_commits[i].author_name.should eq(c.committer_name)

          # Depending upon version of Git used, we may or may not have a trailing \n.
          # We don"t really care, so just compare the stripped versions.
          dest_commits[i].message.strip.should eq(c.message.strip)
        end
      end
    end
  end
end
