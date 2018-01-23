class Shellout
  def self.relay(src, dst)
    while((buf = src.read(8192))); dst << buf; end
  end

  def self.execute(cmd)
    output = IO::Memory.new
    error = IO::Memory.new
    process_status = Process.run(command: cmd, shell: true, output: output, error: error)

    return process_status, output.to_s, error.to_s
  end

  def run(cmd)
    Shellout.execute(cmd)
  end
end
