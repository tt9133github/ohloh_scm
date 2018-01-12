require "../test_helper"

describe "SvnXmlParser" do

  it "basic" do
    assert_convert(SvnXmlParser, DATA_DIR + "/simple.svn_xml_log", DATA_DIR + "/simple.ohlog")
  end

  it "empty_array" do
    assert_equal([], SvnXmlParser.parse(""))
  end

  it "empty_xml" do
    assert_equal("<?xml version=\"1.0\"?>\n<ohloh_log scm=\"svn\">\n</ohloh_log>\n", SvnXmlParser.parse("", :writer => XmlWriter.new))
  end

  it "copy_from" do
    xml = <<-XML
<?xml version="1.0"?>
<log>
<logentry
 revision="8">
<author>robin</author>
<date>2009-02-05T13:40:46.386190Z</date>
<paths>
<path
 copyfrom-path="/branches/development"
 copyfrom-rev="7"
 action="A">/trunk</path>
</paths>
<msg>the branch becomes the new trunk</msg>
</logentry>
</log>
    XML
    commits = SvnXmlParser.parse(xml)
    assert_equal 1, commits.size
    assert_equal 1, commits.first.diffs.size
    assert_equal "/trunk", commits.first.diffs.first.path
    assert_equal "/branches/development", commits.first.diffs.first.from_path
    assert_equal 7, commits.first.diffs.first.from_revision
  end

end
