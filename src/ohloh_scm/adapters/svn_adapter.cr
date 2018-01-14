module OhlohScm::Adapters
  class SvnAdapter < AbstractAdapter
    def english_name
      "Subversion"
    end
  end
end

require "./svn/validation"
require "./svn/cat_file"
require "./svn/commits"
require "./svn/push"
require "./svn/pull"
require "./svn/head"
require "./svn/misc"
require "./svn/patch"

