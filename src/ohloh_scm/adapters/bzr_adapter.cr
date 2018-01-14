module OhlohScm::Adapters
  class BzrAdapter < AbstractAdapter
    def english_name
      "Bazaar"
    end
  end
end

require "./bzr/validation"
require "./bzr/commits"
require "./bzr/head"
require "./bzr/cat_file"
require "./bzr/misc"
require "./bzr/pull"
require "./bzr/push"
