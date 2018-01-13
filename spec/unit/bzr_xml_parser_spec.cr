require "../test_helper"

describe "BzrXmlParser" do

  it "empty_array" do
    BzrXmlParser.parse("").should eq([])
  end

  it "empty_xml" do
    BzrXmlParser.parse("", { :writer => XmlWriter.new }).should eq("<?xml version=\"1.0\"?>\n<ohloh_log scm=\"bzr\">\n</ohloh_log>\n")
  end

  it "basic_xml" do
    xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<logs>
<log>
  <revno>10</revno>
  <revisionid>test@example.com-20110725174345-brbpkwumeh07aoh8</revisionid>
  <parents>
    <parent>amujumdar@blackducksoftware.com-20110722185038-e0i4d1mdxwpipxc4</parent>
  </parents>
  <committer>test &lt;test@example.com&gt;</committer>
  <branch-nick>myproject</branch-nick>
  <timestamp>Mon 2011-07-25 13:43:45 -0400</timestamp>
  <message><![CDATA[Renamed test1.txt to subdir/test_b.txt, removed test2.txt and added test_a.txt.]]></message>
</log>
</logs>
    XML
    commits = BzrXmlParser.parse(xml)
    commits.size.should eq(1)
    c = commits.first
    c.diffs.size.should eq(0)
    c.message.should eq("Renamed test1.txt to subdir/test_b.txt, removed test2.txt and added test_a.txt.")
    c.token.should eq("test@example.com-20110725174345-brbpkwumeh07aoh8")
  end

  it "verbose_xml" do
    xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<logs>
<log>
  <revno>10</revno>
  <revisionid>test@example.com-20110725174345-brbpkwumeh07aoh8</revisionid>
  <parents>
    <parent>amujumdar@blackducksoftware.com-20110722185038-e0i4d1mdxwpipxc4</parent>
  </parents>
  <committer>test &lt;test@example.com&gt;</committer>
  <branch-nick>myproject</branch-nick>
  <timestamp>Mon 2011-07-25 13:43:45 -0400</timestamp>
  <message><![CDATA[Renamed test1.txt to subdir/test_b.txt, removed test2.txt and added test_a.txt.]]></message>
  <affected-files>
    <removed>
      <file fid="test2.txt-20110722163813-257mjqqrvw3mav0f-3">test2.txt</file>
    </removed>
    <added>
      <file fid="test_a.txt-20110725174250-y989xbb6y8ae027k-1">test_a.txt</file>
    </added>
    <renamed>
      <file oldpath="test1.txt" fid="test1.txt-20110722163813-257mjqqrvw3mav0f-2">subdir/test_b.txt</file>
    </renamed>
  </affected-files>
</log>
</logs>
    XML
    commits = BzrXmlParser.parse(xml)
    commits.size.should eq(1)
    c = commits.first
    c.diffs.size.should eq(4) # Rename is a D followed by A

    c.diffs[0].path.should eq("test2.txt")
    c.diffs[0].action.should eq("D")

    c.diffs[1].path.should eq("test_a.txt")
    c.diffs[1].action.should eq("A")

    c.diffs[2].path.should eq("test1.txt")
    c.diffs[2].action.should eq("D")

    c.diffs[3].path.should eq("subdir/test_b.txt")
    c.diffs[3].action.should eq("A")
  end

  # When an directory is deleted, bzr outputs one delete entry
  # per file and one for the directory. For empty dirs, there
  # is only one directory remove entry.
  # Ohloh keeps file delete entries but ignores directory
  # delete entry.
  it "ignore_dir_delete_xml" do
    xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<logs>
<log>
  <revno>720.9.33</revno>
  <revisionid>jano.vesely@gmail.com-20110127220929-d3af6kj4d53lh70t</revisionid>
  <parents>
    <parent>jano.vesely@gmail.com-20110125225108-0vxoig7z3d3q0w0w</parent>
    <parent>vojtechhorky@users.sourceforge.net-20110126145255-4xdar4rxwcrh6s0a</parent>
  </parents>
  <committer>Jan Vesely &lt;jano.vesely@gmail.com&gt;</committer>
  <branch-nick>helenos</branch-nick>
  <timestamp>Thu 2011-01-27 23:09:29 +0100</timestamp>
  <message><![CDATA[Changes from development branch]]></message>
  <affected-files>
    <removed>
      <file fid="nil_interface.h-20100102161837-cblex61ev6y80vjk-59">uspace/lib/net/include/nil_interface.h</file>
      <directory suffix="usb-20100909152052-761ob4st359n02ai-1">uspace/srv/hw/bus/usb/</directory>
      <directory suffix="hcd-20100909152052-761ob4st359n02ai-2">uspace/srv/hw/bus/usb/hcd/</directory>
    </removed>
  </affected-files>
</log>
</logs>
  XML
    commits = BzrXmlParser.parse(xml)
    commits.size.should eq(1)

    c = commits.first
    c.diffs.size.should eq(1)
    c.diffs.first.path.should eq("uspace/lib/net/include/nil_interface.h")
  end

  # bzr also outputs a kind_changed entry when file kind changes, for example
  # a symlink is changed to file.
  # Ohloh ignores such changes.
  it "ignore_kind_changed_xml" do
    xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<logs>
<log>
  <revno>720.9.33</revno>
  <revisionid>jano.vesely@gmail.com-20110127220929-d3af6kj4d53lh70t</revisionid>
  <parents>
    <parent>jano.vesely@gmail.com-20110125225108-0vxoig7z3d3q0w0w</parent>
    <parent>vojtechhorky@users.sourceforge.net-20110126145255-4xdar4rxwcrh6s0a</parent>
  </parents>
  <committer>Jan Vesely &lt;jano.vesely@gmail.com&gt;</committer>
  <branch-nick>helenos</branch-nick>
  <timestamp>Thu 2011-01-27 23:09:29 +0100</timestamp>
  <message><![CDATA[Changes from development branch]]></message>
  <affected-files>
    <removed>
      <file fid="nil_interface.h-20100102161837-cblex61ev6y80vjk-59">uspace/lib/net/include/nil_interface.h</file>
    </removed>
    <added>
      <file fid="mapping1.c-20110121134727-estgg81esab4nuxp-1">uspace/app/tester/mm/mapping1.c</file>
    </added>
    <kind_changed>
      <file oldkind="symlink" suffix="hcd.h-20101204222916-3azlzykk6cxygbzm-1">uspace/lib/usb/include/usb/hcd.h</file>
      <symlink oldkind="file" suffix="addrkeep.h-20101217213828-t8uh2yzhdva01rl9-1">uspace/lib/usb/include/usb/addrkeep.h</symlink>
    </kind_changed>
    <modified>
      <file fid="bzrignore-20101004081108-t6mbnn0isj1l3cpk-1">.bzrignore</file>
    </modified>
  </affected-files>
</log>
</logs>
    XML
    commits = BzrXmlParser.parse(xml)
    commits.size.should eq(1)

    c = commits.first
    c.diffs.size.should eq(3)
    c.diffs[0].action.should eq("D")
    c.diffs[0].path.should eq("uspace/lib/net/include/nil_interface.h")
    c.diffs[1].action.should eq("A")
    c.diffs[1].path.should eq("uspace/app/tester/mm/mapping1.c")
    c.diffs[2].action.should eq("M")
    c.diffs[2].path.should eq(".bzrignore")
  end

  it "different_author_and_committer" do
    xml = <<-XML
<logs>
<log>
  <revno>1</revno>
  <revisionid>amujumdar@blackducksoftware.com-20111011152356-90nluwydpw9g4ncu</revisionid>
  <committer>Abhay Mujumdar &lt;amujumdar@blackducksoftware.com&gt;</committer>
  <branch-nick>bzr_with_authors</branch-nick>
  <timestamp>Tue 2011-10-11 11:23:56 -0400</timestamp>
  <message><![CDATA[Initial.]]></message>
</log>
<log>
  <revno>2</revno>
  <revisionid>amujumdar@blackducksoftware.com-20111011152412-l9ehyruiezws32kj</revisionid>
  <parents>
    <parent>amujumdar@blackducksoftware.com-20111011152356-90nluwydpw9g4ncu</parent>
  </parents>
  <committer>Abhay Mujumdar &lt;amujumdar@blackducksoftware.com&gt;</committer>
  <authors>
    <author>John Doe &lt;johndoe@example.com&gt;</author>
  </authors>
  <branch-nick>bzr_with_authors</branch-nick>
  <timestamp>Tue 2011-10-11 11:24:12 -0400</timestamp>
  <message><![CDATA[Updated.]]></message>
</log>
<log>
  <revno>3</revno>
  <revisionid>test@example.com-20111011162601-ud1nidteswfdbhbu</revisionid>
  <parents>
    <parent>amujumdar@blackducksoftware.com-20111011152412-l9ehyruiezws32kj</parent>
  </parents>
  <committer>test &lt;test@example.com&gt;</committer>
  <authors>
    <author>Jim Beam &lt;jimbeam@example.com&gt;</author>
    <author>Jane Smith &lt;janesmith@example.com&gt;</author>
  </authors>
  <branch-nick>bzr_with_authors</branch-nick>
  <timestamp>Tue 2011-10-11 12:26:01 -0400</timestamp>
  <message><![CDATA[Updated by two authors.]]></message>
</log>
<log>
  <revno>4</revno>
  <revisionid>test@example.com-20111011162601-dummyrevision</revisionid>
  <parents>
    <parent>test@example.com-20111011162601-ud1nidteswfdbhbu</parent>
  </parents>
  <committer>test &lt;test@example.com&gt;</committer>
  <branch-nick>bzr_with_authors</branch-nick>
  <timestamp>Tue 2011-10-11 12:28:01 -0400</timestamp>
  <message><![CDATA[Updated by committer.]]></message>
</log>
</logs>
    XML
    commits = BzrXmlParser.parse(xml)
    c = commits[0]
    c.committer_name.should eq("Abhay Mujumdar")
    c.committer_email.should eq("amujumdar@blackducksoftware.com")

    c = commits[1]
    c.committer_name.should eq("Abhay Mujumdar")
    c.committer_email.should eq("amujumdar@blackducksoftware.com")
    c.author_name.should eq("John Doe")
    c.author_email.should eq("johndoe@example.com")

    c = commits[2]
    c.committer_name.should eq("test")
    c.committer_email.should eq("test@example.com")
    c.author_name.should eq("Jim Beam")
    c.author_email.should eq("jimbeam@example.com")

    c = commits[3]
    c.committer_name.should eq("test")
    c.committer_email.should eq("test@example.com")
    c.author_name.should eq(nil)
    c.author_email.should eq(nil)
  end

  it "rename" do
    xml = <<-XML
<logs>
<log>
  <revno>10</revno>
  <revisionid>test@example.com-20110725174345-brbpkwumeh07aoh8</revisionid>
  <parents>
    <parent>amujumdar@blackducksoftware.com-20110722185038-e0i4d1mdxwpipxc4</parent>
  </parents>
  <committer>test &lt;test@example.com&gt;</committer>
  <branch-nick>myproject</branch-nick>
  <timestamp>Mon 2011-07-25 13:43:45 -0400</timestamp>
  <message><![CDATA[Renamed test1.txt to subdir/test_b.txt, removed test2.txt and added test_a.txt.]]></message>
  <affected-files>
    <renamed>
      <file oldpath="test1.txt" fid="test1.txt-20110722163813-257mjqqrvw3mav0f-2">subdir/test_b.txt</file>
    </renamed>
  </affected-files>
</log>
</logs>
    XML
    commits = BzrXmlParser.parse(xml)
    commits.size.should eq(1)
    commits.first.diffs.size.should eq(2)
    commits.first.diffs.first.action.should eq("D")
    commits.first.diffs.first.path.should eq("test1.txt")

    commits.first.diffs.last.action.should eq("A")
    commits.first.diffs.last.path.should eq("subdir/test_b.txt")
  end

  it "remove_dupes_add_remove" do
    diffs = BzrXmlParser.remove_dupes([ OhlohScm::Diff.new({:action => "A", :path => "foo"}),
                                      OhlohScm::Diff.new({:action => "D", :path => "foo"}) ])
    diffs.size.should eq(1)
    diffs.first.action.should eq("M")
    diffs.first.path.should eq("foo")
  end

  # A complex delete/rename/modify test.
  # Removed test_a.txt, Renamed test3.txt to test_a.txt, edited test_a.txt
  #
  # This is what Ohloh expects to see:
  #
  #   D  test3.txt
  #   M  test_a.txt
  #
  it "complex_rename" do
    xml = <<-XML
<logs>
<log>
  <revno>11</revno>
  <revisionid>test@example.com-20111012191732-h3bt3lp6l38vbm9v</revisionid>
  <parents>
    <parent>test@example.com-20110725174345-brbpkwumeh07aoh8</parent>
  </parents>
  <committer>test &lt;test@example.com&gt;</committer>
  <branch-nick>myproject</branch-nick>
  <timestamp>Wed 2011-10-12 15:17:32 -0400</timestamp>
  <message><![CDATA[Removed test_a.txt, Renamed test3.txt to test_a.txt, edited test_a.txt.]]></message>
  <affected-files>
    <removed>
      <file fid="test_a.txt-20110725174250-y989xbb6y8ae027k-1">test_a.txt</file>
    </removed>
    <renamed>
      <file oldpath="test3.txt" fid="test3.txt-20110722163813-257mjqqrvw3mav0f-4">test_a.txt</file>
    </renamed>
    <modified>
      <file fid="test3.txt-20110722163813-257mjqqrvw3mav0f-4">test_a.txt</file>
    </modified>
  </affected-files>
</log>
</logs>
    XML
    diffs = BzrXmlParser.parse(xml).first.diffs
    diffs.sort! { |a,b| a.action <=> b.action }
    diffs.size.should eq(2)
    diffs.first.action.should eq("D")
    diffs.first.path.should eq("test3.txt")
    diffs.last.action.should eq("M")
    diffs.last.path.should eq("test_a.txt")
  end

  # This test-case also tests rename and modify in the same commit.
  # A rename and modify should result in a DELETE and an ADD.
  it "strip_trailing_asterisk_from_executables" do
    xml = <<-XML
<logs>
<log>
  <revno>14</revno>
  <revisionid>test@example.com-20111012195747-seei62z2wmefjhmo</revisionid>
  <parents>
    <parent>test@example.com-20111012195606-0shla0kf4e8hq4mq</parent>
  </parents>
  <committer>test &lt;test@example.com&gt;</committer>
  <branch-nick>myproject</branch-nick>
  <timestamp>Wed 2011-10-12 15:57:47 -0400</timestamp>
  <message><![CDATA[Changed +x on arch and then renamed arch to renamed_arch.]]></message>
  <affected-files>
    <renamed>
      <file oldpath="arch" meta_modified="true" fid="arch-20111012194919-geu209qc2loshh3i-1">renamed_arch</file>
    </renamed>
    <modified>
      <file fid="arch-20111012194919-geu209qc2loshh3i-1">renamed_arch*</file>
    </modified>
  </affected-files>
</log>
</logs>
    XML
    diffs = BzrXmlParser.parse(xml).first.diffs
    diffs.sort! { |a,b| a.action <=> b.action }
    diffs[0].action.should eq("A")
    diffs[0].path.should eq("renamed_arch")
    diffs[1].action.should eq("D")
    diffs[1].path.should eq("arch")
  end

  it "committer_name_capture" do
    name, email = BzrXmlParser.capture_name("John")
    "John".should eq(name)
    nil.should eq(email)
    BzrXmlParser.capture_name("John Doe").should eq(["John Doe", nil])
    BzrXmlParser.capture_name("John Doe jdoe@example.com").should eq(["John Doe jdoe@example.com", nil])
    BzrXmlParser.capture_name("John Doe <jdoe@example.com").should eq(["John Doe <jdoe@example.com", nil])
    BzrXmlParser.capture_name("John Doe jdoe@example.com>").should eq(["John Doe jdoe@example.com>", nil])
    BzrXmlParser.capture_name("John Doe <jdoe@example.com>").should eq(["John Doe", "jdoe@example.com"])
    BzrXmlParser.capture_name("John Doe     <jdoe@example.com>   ").should eq(["John Doe", "jdoe@example.com"])
    BzrXmlParser.capture_name("jdoe@example.com").should eq(["jdoe@example.com", nil])
    xml = <<-XML
<logs>
<log>
  <revno>15</revno>
  <revisionid>a@b.com-20111013152207-q8uec9pp1330gfbh</revisionid>
  <parents>
    <parent>test@example.com-20111012195747-seei62z2wmefjhmo</parent>
  </parents>
  <committer>a@b.com</committer>
  <authors>
    <author>author@c.com</author>
  </authors>
  <branch-nick>myproject</branch-nick>
  <timestamp>Thu 2011-10-13 11:22:07 -0400</timestamp>
  <message><![CDATA[Updated with only email as committer name.]]></message>
  <affected-files>
    <modified>
      <file fid="test3.txt-20110722163813-257mjqqrvw3mav0f-4">test_a.txt</file>
    </modified>
  </affected-files>
</log>
</logs>
    XML
    c = BzrXmlParser.parse(xml).first
    c.diffs.first.action.should eq("M")
    c.diffs.first.path.should eq("test_a.txt")
    c.committer_name.should eq("a@b.com")
    c.committer_email.should eq(nil)
    c.author_name.should eq("author@c.com")
    c.author_email.should eq(nil)
  end
end
