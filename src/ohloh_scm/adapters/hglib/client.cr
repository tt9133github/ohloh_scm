require "../../python_bridge"

class HglibClient
  SCRIPT_PATH = File.dirname(__FILE__) + "/server.py"

  def initialize(@repository_url : String)
  end

  def cat_file(revision, file)
    begin
      send_command("CAT_FILE\t#{revision}\t#{file}")
    rescue e : Exception
      if e.message =~ /not found in manifest/
        return nil # File does not exist.
      else
        raise Exception.new
      end
    end
  end

  def parent_tokens(revision)
    send_command("PARENT_TOKENS\t#{revision}").to_s.split("\t")
  end

  def send_command(cmd)
    PythonBridge.exec(SCRIPT_PATH, "REPO_OPEN\t#{@repository_url}", cmd)
  end
end
