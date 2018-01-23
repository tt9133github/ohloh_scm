require "../spec_helper"

describe "ScratchDir" do
  it "must work" do
    OhlohScm::ScratchDir.new do |path|
      status, out_message, err_message = Shellout.execute("ls #{path}")
      status.success?.should be_true
    end
  end
end
