module OhlohScm::Adapters
  class CvsAdapter < AbstractAdapter
    property :module_name

    def english_name
      "CVS"
    end
  end
end

require "./cvs/validation"
require "./cvs/commits"
require "./cvs/misc"
