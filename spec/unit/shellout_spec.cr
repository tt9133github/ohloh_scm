require "../spec_helper"

describe "Shellout" do
  it "execute_must_pipe_the_results_accurately" do
    status, out_message, err_message = Shellout.execute("ruby -e 'puts %[hello world]; STDERR.puts(%[some error])'")

    out_message.should eq("hello world\n")
    err_message.should eq("some error\n")
  end

  it "execute_must_return_appropriate_status_for_a_failed_process" do
    status, out_message, err_message = Shellout.execute("/bin/false")

    status.success?.should be_false
  end

  it "execute_must_not_hang_when_io_buffer_is_full" do
    # TODO: Make this work.
    # STDOUT.write_timeout = 1
    # Shellout.execute("ruby -e 'STDERR.puts(%[some line\n] * 10000)'")
  end
end
