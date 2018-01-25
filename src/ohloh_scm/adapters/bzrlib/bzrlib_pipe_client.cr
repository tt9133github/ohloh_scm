require "../../python_bridge"

class BzrPipeClient
  SCRIPT_PATH = File.dirname(__FILE__) + "/bzrlib_pipe_server.py"

  def initialize(@repository_url : String)
  end

  def cat_file(revision, file)
    send_command("CAT_FILE|#{revision}|#{file}")
  end

  def parent_tokens(revision)
    send_command("PARENT_TOKENS|#{revision}").to_s.split("|")
  end

  def send_command(cmd)
    PythonBridge.exec(SCRIPT_PATH, "REPO_OPEN|#{@repository_url}", cmd)
  end
end
