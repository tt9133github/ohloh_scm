module OhlohScm::Adapters
  class AbstractAdapter

    def is_merge_commit?(commit)
      false
    end

    def tags
      Array(Nil).new
    end

  end
end
