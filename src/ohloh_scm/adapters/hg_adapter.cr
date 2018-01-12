module OhlohScm::Adapters
  class HgAdapter < AbstractAdapter
    def english_name
      "Mercurial"
    end

    def branch_name=(branch_name)
      branch_name = nil if branch_name.to_s.empty?
      super
    end
  end
end

require "./hg/validation"
require "./hg/cat_file"
require "./hg/commits"
require "./hg/misc"
require "./hg/pull"
require "./hg/push"
require "./hg/head"
require "./hg/patch"
