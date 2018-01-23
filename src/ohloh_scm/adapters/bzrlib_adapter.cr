require "./bzrlib/bzrlib_pipe_client"
module OhlohScm::Adapters
  class BzrlibAdapter < BzrAdapter
    @bzr_client : BzrPipeClient | Nil

    def setup
      @bzr_client = BzrPipeClient.new(url)
      @bzr_client.as(BzrPipeClient).start
      @bzr_client.as(BzrPipeClient)
    end

    def bzr_client
      @bzr_client || setup
    end

    def cleanup
      @bzr_client.shutdown
    end

  end
end

require "./bzrlib/head"
require "./bzrlib/cat_file"
