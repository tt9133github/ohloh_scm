module OhlohScm::Adapters
  class HgAdapter < AbstractAdapter
    def cat_file(commit, diff)
      cat(commit.token, diff.path)
    end

    def cat_file_parent(commit, diff)
      p = parent_tokens(commit)
      cat(p.first, diff.path) if p.first?
    end

    def cat(revision, path)
      output, err = run_with_err(%(cd '#{url}' && hg cat -r #{revision} #{escape(path)}))
      return nil if err =~ /No such file in rev/i
      raise Exception.new(err) unless err.to_s == ""
      output
    end

    # Escape bash-significant characters in the filename
    # Example:
    #     "Foo Bar & Baz" => "Foo\ Bar\ \&\ Baz"
    def escape(path)
      # FIXME: path.to_s.shellescape
      path.to_s.gsub(/(\s|&|\/|\\|:|\(|\)|\|\*|#|"|'|`|\$|\|)/) { "\\#{$1}" }
    end
  end
end
