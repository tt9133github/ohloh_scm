require "./hglib/client"

module OhlohScm::Adapters
  class HglibAdapter < HgAdapter
    def hg_client
      HglibClient.new(url)
    end
  end
end

require "./hglib/head"
require "./hglib/cat_file"
