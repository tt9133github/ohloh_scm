module OhlohScm
  class NullCommit < Commit
    def null?
      true
    end
  end
end
