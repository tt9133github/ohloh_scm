require "../spec_helper"

describe "SvnXmlParser" do

  it "empty_array" do
    SvnXmlParser.parse("").should eq(Array(Nil).new)
  end

  it "empty_xml" do
    # SvnXmlParser.parse("", writer: XmlWriter.new).should eq("<?xml version=\"1.0\"?>\n<ohloh_log scm=\"svn\">\n</ohloh_log>\n")
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
    commits.size.should eq(1)
    commits.first.diffs.size.should eq(1)
    commits.first.diffs.first.path.should eq("/trunk")
    commits.first.diffs.first.from_path.should eq("/branches/development")
    commits.first.diffs.first.from_revision.should eq(7)
  end

end
