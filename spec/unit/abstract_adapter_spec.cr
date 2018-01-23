require "../spec_helper"

describe "AbstractAdapter" do
  it "simple_validation" do
    scm = AbstractAdapter.new
    scm.valid?.should be_falsey
    scm.errors.should eq([["url", "The URL can't be blank."]])

    scm.url = "http://www.test.org/test"
    scm.valid?.should be_truthy
    scm.errors.empty?.should be_truthy
  end

  it "valid_urls" do
    ["http://www.ohloh.net"].each do |url|
      AbstractAdapter.new(url: url).validate_url.should be_falsey
    end
  end

  it "invalid_urls" do
    ["", "", "*" * 121].each do |url|
      AbstractAdapter.new(url: url).validate_url.to_s.empty?.should be_false
    end
  end

  it "invalid_usernames" do
    ["no spaces allowed", "/", ":", "a"*33].each do |username|
      AbstractAdapter.new(username: username).validate_username.to_s.empty?.should be_false
    end
  end

  it "valid_usernames" do
    ["","joe_36","a"*32].each do |username|
      AbstractAdapter.new(username: username).validate_username.should be_falsey
    end
  end

  it "invalid_passwords" do
    ["no spaces allowed", "a"*33].each do |password|
      AbstractAdapter.new(password: password).validate_password.to_s.empty?.should be_false
    end
  end

  it "valid_passwords" do
    ["","abc","a"*32].each do |password|
      AbstractAdapter.new(password: password).validate_password.should be_falsey
    end
  end

  it "invalid_branch_names" do
    ["%","a"*81].each do |branch_name|
      AbstractAdapter.new(branch_name: branch_name).validate_branch_name.to_s.empty?.should be_false
    end
  end

  it "valid_branch_names" do
    ["","/trunk","_","a"*80].each do |branch_name|
      AbstractAdapter.new(branch_name: branch_name).validate_branch_name.should be_falsey
    end
  end

  it "normalize" do
    scm = AbstractAdapter.new(url: "   http://www.test.org/test   ", username: "  joe  ", password: "  abc  ", branch_name: "   trunk  ")
    scm.normalize
    scm.url.should eq("http://www.test.org/test")
    scm.branch_name.should eq("trunk")
    scm.username.should eq("joe")
    scm.password.should eq("abc")
  end

  it "shellout" do
    cmd =  %q( ruby -e"  t = 'Hello World'; STDOUT.puts t; STDERR.puts t  " )
    stdout = AbstractAdapter.run(cmd)
    stdout.should eq("Hello World\n")
  end

  it "shellout_with_stderr" do
    cmd = %q( ruby -e"  t = 'Hello World'; STDOUT.puts t; STDERR.puts t  " )
    stdout, stderr, status = AbstractAdapter.run_with_err(cmd)
    status.should eq(0)
    stdout.should eq("Hello World\n")
    stderr.should eq("Hello World\n")
  end

  it "shellout_large_output" do
    cat = %(ruby -e"  puts Array.new(65536){ 42 }  ")
    stdout = AbstractAdapter.run(cat)
    stdout.should eq(Array.new(65536){ 42 }.join("\n") + "\n")
  end

  it "shellout_error" do
    cmd = "false"
    expect_raises(Exception) do
      stdout = AbstractAdapter.run(cmd)
    end
  end

  it "string_encoder_must_return_path_to_script" do
    string_encoder_path = File.expand_path("../../../bin/string_encoder", __FILE__)

    AbstractAdapter.new.string_encoder.should eq(string_encoder_path)
  end
end
