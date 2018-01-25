module PythonBridge
  extend self

  def open_repository(process, repo_command)
    process.input.puts(repo_command)
    process.error.gets(10)
  end

  def exec(script_path, repo_command, cmd)
    Process.run(command: "python #{script_path}", shell: true) do |process|
      open_repository(process, repo_command)

      process.input.puts cmd
      process.input.flush
      return read_output(process)
    end
  end

  def read_output(process)
    status = process.error.gets(10)
    # Get status on stderr. e.g. T000000042
    # First letter indicates state, remaining value indicates IO length.
    flag = status[0,1] if status
    size = status ? status[1,9].to_i : 0

    # read content from stdout
    process.output.read_string(size) unless no_exceptions?(process, flag, size)
  end

  def no_exceptions?(process, flag, size)
    if flag == "E"
      error = process.output.read_string(size)
      raise Exception.new("Exception in server process\n#{error}")
    end
    flag == "F"
  end
end
