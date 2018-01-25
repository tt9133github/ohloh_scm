require "./bzrlib/bzrlib_pipe_client"
module OhlohScm::Adapters
  class BzrlibAdapter < BzrAdapter
    def bzr_client
      BzrPipeClient.new(url)
    end
  end
end

require "./bzrlib/head"
require "./bzrlib/cat_file"
