describe "CommandLine" do
  it "cvs_from_file" do
    result = `#{File.dirname(__FILE__) + "/../../bin/ohlog"} --xml --cvs #{DATA_DIR + "/basic.rlog"}`
    assert_equal 0, $?
    assert_buffers_equal File.read(DATA_DIR + "/basic.ohlog"), result
  end

  it "cvs_from_pipe" do
    result = `cat #{DATA_DIR + "/basic.rlog"} | #{File.dirname(__FILE__) + "/../../bin/ohlog"} --xml --cvs`
    assert_equal 0, $?
    assert_buffers_equal File.read(DATA_DIR + "/basic.ohlog"), result
  end

  it "svn_from_file" do
    result = `#{File.dirname(__FILE__) + "/../../bin/ohlog"} --xml --svn #{DATA_DIR + "/simple.svn_log"}`
    assert_equal 0, $?
    assert_buffers_equal File.read(DATA_DIR + "/simple.ohlog"), result
  end

  it "svn_xml_from_file" do
    result = `#{File.dirname(__FILE__) + "/../../bin/ohlog"} --xml --svn-xml #{DATA_DIR + "/simple.svn_xml_log"}`
    assert_equal 0, $?
    assert_buffers_equal File.read(DATA_DIR + "/simple.ohlog"), result
  end

  it "hg_from_file" do
  end

  it "help" do
    result = `#{File.dirname(__FILE__) + "/../../bin/ohlog"} -?`
    assert_equal 0, $?
    assert result =~ /Examples:/
  end
end
