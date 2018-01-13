require "../test_helper"
require "timeout"

describe "Shellout" do
  it "execute_must_pipe_the_results_accurately" do
    status, out, err = Shellout.execute("ruby -e 'puts %[hello world]; STDERR.puts(%[some error])'")

    "hello world\n".should eq(out)
    "some error\n".should eq(err)
    true.should eq(status.success?)
  end

  it "execute_must_return_appropriate_status_for_a_failed_process" do
    status, out, err = Shellout.execute("ruby -e 'exit(1)'")

    false.should eq(status.success?)
  end

  it "execute_must_not_hang_when_io_buffer_is_full" do
    Timeout::timeout(1) do
      Shellout.execute("ruby -e 'STDERR.puts(%[some line\n] * 10000)'")
    end
  end
end
