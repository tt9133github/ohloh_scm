module OhlohScm::Adapters
  class GitAdapter < AbstractAdapter
    def english_name
      "Git"
    end
  end
end

require "./git/validation"
require "./git/cat_file"
require "./git/commits"
require "./git/commit_all"
require "./git/token"
require "./git/push"
require "./git/pull"
require "./git/head"
require "./git/misc"
require "./git/patch"
