require 'spec_helper'

describe 'GitSvnScm' do
  it 'must conver to git Repository' do
    with_git_svn_repository('svn') do |src|
      Dir.mktmpdir do |_dir|
        OhlohScm::GitSvnScm.any_instance.expects(:run).twice
        src.scm.pull(src)
      end
    end
  end

  it 'must fetch the repo' do
    OhlohScm::GitSvnScm.any_instance.expects(:run).times(3)
    with_git_svn_repository('git_svn') do |git_svn|
      git_svn.scm.pull(git_svn)
    end
  end

  it 'must return all commit tokens' do
    with_git_svn_repository('git_svn') do |git_svn|
      git_svn.activity.commit_tokens.must_equal [1, 2, 3, 5]
      git_svn.activity.commit_tokens(after: 2).must_equal [3, 5]
    end
  end

  it 'must return commits' do
    with_git_svn_repository('git_svn') do |git_svn|
      git_svn.activity.commits.map(&:token).must_equal [1, 2, 3, 5]
      git_svn.activity.commits(after: 2).map(&:token).must_equal [3, 5]
      git_svn.activity.commits(after: 7).map(&:token).must_equal []
    end
  end

  it 'must iterate each commit' do
    with_git_svn_repository('git_svn') do |git_svn|
      commits = []
      git_svn.activity.each_commit { |c| commits << c }
      git_svn.activity.commits.map(&:token).must_equal [1, 2, 3, 5]
    end
  end

  it 'must return total commit count' do
    with_git_svn_repository('git_svn') do |git_svn|
      git_svn.activity.commit_count.must_equal 4
      git_svn.activity.commit_count(after: 2).must_equal 2
    end
  end

  it 'must give source scm commit count' do
    with_git_svn_repository('svn', 'trunk') do |svn|
      with_git_svn_repository('git_svn') do |git_svn|
        git_svn.activity.source_scm_commit_count(source_scm: svn).must_equal 0
      end
    end
  end

  it '#cat_file' do
    with_git_svn_repository('git_svn') do |git_svn|
      expected = <<-EXPECTED.gsub(/^\s+/, '')
          /* Hello, World! */
          #include <stdio.h>
          main()
          {
            printf("Hello, World!\\n");
          }
      EXPECTED

      git_svn.activity.cat_file(OhlohScm::Commit.new(token: 1),
                                OhlohScm::Diff.new(path: 'helloworld.c')).delete("\t").strip.must_equal expected.strip
    end
  end

  it 'must cat_file with non existent token' do
    with_git_svn_repository('git_svn') do |git_svn|
      assert git_svn.activity.cat_file(OhlohScm::Commit.new(token: 999), OhlohScm::Diff.new(path: 'helloworld.c'))
    end
  end

  it 'must cat_file with invalid filename' do
    with_git_svn_repository('git_svn') do |git_svn|
      lambda {
        git_svn.activity.cat_file(OhlohScm::Commit.new(token: 1), OhlohScm::Diff.new(path: 'invalid'))
      }.must_raise RuntimeError
    end
  end

  it '#cat_file_parent' do
    with_git_svn_repository('git_svn') do |git_svn|
      expected = <<-EXPECTED.gsub(/^\s+/, '')
          /* Hello, World! */
          #include <stdio.h>
          main()
          {
            printf("Hello, World!\\n");
          }
      EXPECTED

      git_svn.activity.cat_file_parent(OhlohScm::Commit.new(token: 2),
                                       OhlohScm::Diff.new(path: 'helloworld.c')).delete("\t").must_equal expected.strip
    end
  end

  it 'must cat_file_parent with first token' do
    with_git_svn_repository('git_svn') do |git_svn|
      assert git_svn.activity.cat_file(OhlohScm::Commit.new(token: 1), OhlohScm::Diff.new(path: 'helloworld.c'))
    end
  end

  it '#path_to_file_url' do
    get_base(url: '').scm.send(:path_to_file_url, '').must_be_nil
    get_base(url: '/home/test').scm.send(:path_to_file_url, '/home/test').must_equal 'file:///home/test'
  end

  it 'should require https for sourceforge' do
    url = '://svn.code.sf.net/p/gallery/code/trunk/gallery2'
    get_base(url: "http#{url}").scm.normalize.url.must_equal "https#{url}"
    get_base(url: "https#{url}").scm.normalize.url.must_equal "https#{url}"

    url = 'https://github.com/blackducksw/ohloh_scm/trunk'
    get_base(url: url).scm.normalize.url.must_equal url
  end

  it 'should recalc branch name' do
    with_git_svn_repository('svn') do |svn|
      git_svn = get_base(url: svn.scm.url, branch_name: '').scm
      git_svn.branch_name.must_be_empty
      git_svn.send(:recalc_branch_name).must_be_empty
      git_svn.branch_name.must_be_empty

      git_svn = get_base(url: svn.scm.url, branch_name: '/').scm
      git_svn.send(:recalc_branch_name).must_be_empty
      git_svn.branch_name.must_be_empty

      git_svn = get_base(url: svn.scm.url + '/trunk').scm
      OhlohScm::GitSvnActivity.any_instance.stubs(:root).returns(svn.scm.url)
      git_svn.send(:recalc_branch_name)
      git_svn.branch_name.must_equal '/trunk'

      git_svn = get_base(url: svn.scm.url + '/trunk', branch_name: nil).scm
      OhlohScm::GitSvnActivity.any_instance.stubs(:root).returns(svn.scm.url)
      OhlohScm::GitSvnScm.any_instance.stubs(:branch_name).returns(nil)
      git_svn.normalize.branch_name.must_equal nil
    end
  end

  def get_base(opts)
    OhlohScm::Factory.get_base({ scm_type: :git_svn, url: 'foo' }.merge(opts))
  end
end
