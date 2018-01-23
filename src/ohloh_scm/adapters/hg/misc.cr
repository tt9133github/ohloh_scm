module OhlohScm::Adapters
  class HgAdapter < AbstractAdapter
    def exist?
      begin
        !!(head_token)
      rescue
        # FIXME: logger.debug { $! }
        false
      end
    end

    def ls_tree(token)
      run("cd '#{path}' && hg manifest -r #{token} | #{ string_encoder }").split("\n", remove_empty: true)
    end

    def export(dest_dir, token="tip")
      run("cd '#{path}' && hg archive -r #{token} '#{dest_dir}'")
      # Hg leaves a little cookie crumb in the export directory. Remove it.
      File.delete(File.join(dest_dir, ".hg_archival.txt")) if File.exists?(File.join(dest_dir, ".hg_archival.txt"))
    end

    def tags
      tag_strings = run("cd '#{path}' && hg tags").split(/\n/, remove_empty: true)
      tag_strings.map do |tag_string|
        tag_name, rev_number_and_hash = tag_string.split(/\s+/)
        rev = rev_number_and_hash.match(/\A\d+/).try(&.[0])
        time_string = run("cd '#{ path }' && hg log -r #{ rev } | grep 'date:' | sed -E 's/date:\\s+//'")
        [tag_name, rev, Time.parse(time_string, "%a %b %d %T %Y %z")]
      end
    end
  end
end
