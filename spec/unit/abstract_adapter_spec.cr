require "../test_helper"

describe "AbstractAdapter" do
  it "simple_validation" do
    scm = AbstractAdapter.new()
    assert !scm.valid?
    assert_equal [[:url, "The URL can't be blank."]], scm.errors

    scm.url = "http://www.test.org/test"
    assert scm.valid?
    assert scm.errors.empty?
  end

  it "valid_urls" do
    ["http://www.ohloh.net"].each do |url|
      assert !AbstractAdapter.new(:url => url).validate_url
    end
  end

  it "invalid_urls" do
    [nil, "", "*" * 121].each do |url|
      assert AbstractAdapter.new(:url => url).validate_url.any?
    end
  end

  it "invalid_usernames" do
    ["no spaces allowed", "/", ":", "a"*33].each do |username|
      assert AbstractAdapter.new(:username => username).validate_username.any?
    end
  end

  it "valid_usernames" do
    [nil,"","joe_36","a"*32].each do |username|
      assert !AbstractAdapter.new(:username => username).validate_username
    end
  end

  it "invalid_passwords" do
    ["no spaces allowed", "a"*33].each do |password|
      assert AbstractAdapter.new(:password => password).validate_password.any?
    end
  end

  it "valid_passwords" do
    [nil,"","abc","a"*32].each do |password|
      assert !AbstractAdapter.new(:password => password).validate_password
    end
  end

  it "invalid_branch_names" do
    ["%","a"*81].each do |branch_name|
      assert AbstractAdapter.new(:branch_name => branch_name).validate_branch_name.any?
    end
  end

  it "valid_branch_names" do
    [nil,"","/trunk","_","a"*80].each do |branch_name|
      assert !AbstractAdapter.new(:branch_name => branch_name).validate_branch_name
    end
  end

  it "normalize" do
    scm = AbstractAdapter.new(:url => "   http://www.test.org/test   ", :username => "  joe  ", :password => "  abc  ", :branch_name => "   trunk  ")
    scm.normalize
    assert_equal "http://www.test.org/test", scm.url
    assert_equal "trunk", scm.branch_name
    assert_equal "joe", scm.username
    assert_equal "abc", scm.password
  end

  it "shellout" do
    cmd =  %q( ruby -e"  t = 'Hello World'; STDOUT.puts t; STDERR.puts t  " )
    stdout = AbstractAdapter.run(cmd)
    assert_equal "Hello World\n", stdout
  end

  it "shellout_with_stderr" do
    cmd = %q( ruby -e"  t = 'Hello World'; STDOUT.puts t; STDERR.puts t  " )
    stdout, stderr, status = AbstractAdapter.run_with_err(cmd)
    assert_equal 0, status.exitstatus
    assert_equal "Hello World\n", stdout
    assert_equal "Hello World\n", stderr
  end

  it "shellout_large_output" do
    cat = %(ruby -e"  puts Array.new(65536){ 42 }  ")
    stdout = AbstractAdapter.run(cat)
    assert_equal Array.new(65536){ 42 }.join("\n").concat("\n"), stdout
  end

  it "shellout_error" do
    cmd = "false"
    assert_raise RuntimeError do
      stdout = AbstractAdapter.run(cmd)
    end
  end

  it "string_encoder_must_return_path_to_script" do
    string_encoder_path = File.expand_path("../../../bin/string_encoder", __FILE__)

    assert_equal string_encoder_path, AbstractAdapter.new.string_encoder
  end

end
