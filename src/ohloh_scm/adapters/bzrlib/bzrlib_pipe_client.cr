class BzrPipeClient
  SCRIPT_PATH = File.dirname(__FILE__) + "/bzrlib_pipe_server.py"

  def initialize(@repository_url : String)
  end

  def start
    @stdout = IO::Memory.new
    @stderr = IO::Memory.new
    @stdin = IO::Memory.new
    @process = Process.new(command: "python #{SCRIPT_PATH}", shell: true,
                           input: @stdin.as(IO::Memory), output: @stdout.as(IO::Memory), error: @stderr.as(IO::Memory))
    open_repository
  end

  def open_repository
    send_command("REPO_OPEN|#{@repository_url}")
  end
  def cat_file(revision, file)
    send_command("CAT_FILE|#{revision}|#{file}")
  end

  def parent_tokens(revision)
    send_command("PARENT_TOKENS|#{revision}").to_s.split("|")
  end

  def send_command(cmd)
    # send the command
    @stdin.as(IO::Memory).puts cmd
    @stdin.as(IO::Memory).flush
    return if cmd == "QUIT"

    # get status on stderr, first letter indicates state,
    # remaing value indicates length of the file content
    status = @stderr.as(IO::Memory).gets(10)
    flag = status[0,1] if status
    size = status[1,9].to_i if status
    if flag == "F"
      return nil
    elsif flag == "E"
      error = @stdout.as(IO::Memory).gets(size)
      raise Exception.new("Exception in server process\n#{error}")
    end

    # read content from stdout
    return @stdout.as(IO::Memory).gets(size)
  end

  def shutdown
    send_command("QUIT")
    [@stdout, @stdin, @stderr].each { |io| io.close unless io.closed? }
    @process.wait
  end
end

def cat_all_files(client, datafile)
  count = 0
  bytes = 0
  File.open(datafile).each do |line|
    parts = line.split("|")
    count = count + 1
    bytes = bytes + client.cat_file(parts[0], parts[1]).size
    puts "file=#{count}, bytes=#{bytes}"
  end
end

def all_parent_tokens(client, datafile)
  File.open(datafile).each do |line|
    parts = line.split("|")
    puts client.parent_tokens(parts[0])
  end
end
