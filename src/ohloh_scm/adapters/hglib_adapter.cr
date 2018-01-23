require "./hglib/client"

module OhlohScm::Adapters
  class HglibAdapter < HgAdapter
    @hg_client : HglibClient | Nil

    def setup
      @hg_client = HglibClient.new(url)
      @hg_client.as(HglibClient).start
      @hg_client.as(HglibClient)
    end

    def hg_client
      @hg_client || setup
    end

    def cleanup
      @hg_client && @hg_client.shutdown
    end

  end
end

require "./hglib/head"
require "./hglib/cat_file"
