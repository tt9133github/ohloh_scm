module Shellout
  extend self

  def escape(filename)
    URI.escape(filename) do |byte|
      URI.unreserved?(byte) || "/\\:()\"*<>|".includes?(byte.chr)
    end
  end

  def relay(src, dst)
    while((buf = src.read(8192))); dst << buf; end
  end

  def execute(cmd)
    output = IO::Memory.new
    error = IO::Memory.new
    process_status = Process.run(command: cmd, shell: true, output: output, error: error)

    return process_status, output.to_s, error.to_s
  end
end
