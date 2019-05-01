require 'spec_helper'

describe 'GitSvnScm' do
  it 'must conver to git Repository' do
    with_git_svn_repository('svn') do |git_svn|
      Dir.mktmpdir do |dir|
        git_svn.scm.pull
      end
    end
  end
end
