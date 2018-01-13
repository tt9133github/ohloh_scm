require "../test_helper"

describe "CvsMisc" do
  it "local_directory_trim" do
    r = CvsAdapter.new(:url => "/Users/robin/cvs_repo/", :module_name => "simple")
    r.trim_directory("/Users/robin/cvs_repo/simple/foo.rb").should eq("/Users/robin/cvs_repo/simple/foo.rb")
  end

  it "remote_directory_trim" do
    r = CvsAdapter.new(:url => ":pserver:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle", :module_name => "contrib")
    r.trim_directory("/cvsroot/moodle/contrib/foo.rb").should eq("foo.rb")
  end

  it "remote_directory_trim_with_port_number" do
    r = CvsAdapter.new(:url => ":pserver:anoncvs:anoncvs@libvirt.org:2401/data/cvs", :module_name => "libvirt")
    r.trim_directory("/data/cvs/libvirt/docs/html/Attic").should eq("docs/html/Attic")
  end

  it "ordered_directory_list" do
    r = CvsAdapter.new(:url => ":pserver:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle", :module_name => "contrib")

    l = r.build_ordered_directory_list(["/cvsroot/moodle/contrib/foo/bar".intern,
                                      "/cvsroot/moodle/contrib".intern,
                                      "/cvsroot/moodle/contrib/hello".intern,
                                      "/cvsroot/moodle/contrib/hello".intern])

    l.size.should eq(4)
    l[0].should eq("")
    l[1].should eq("foo")
    l[2].should eq("hello")
    l[3].should eq("foo/bar")
  end

  it "ordered_directory_list_ignores_Attic" do
    r = CvsAdapter.new(:url => ":pserver:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle", :module_name => "contrib")

    l = r.build_ordered_directory_list(["/cvsroot/moodle/contrib/foo/bar".intern,
                                      "/cvsroot/moodle/contrib/Attic".intern,
                                      "/cvsroot/moodle/contrib/hello/Attic".intern])

    l.size.should eq(4)
    l[0].should eq("")
    l[1].should eq("foo")
    l[2].should eq("hello")
    l[3].should eq("foo/bar")
  end

  def host
    r = CvsAdapter.new(:url => ":ext:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle", :module_name => "contrib")
    r.host.should eq("moodle.cvs.sourceforge.net")
  end

  def protocol
    CvsAdapter.new(:url => ":pserver:foo:@foo.com:/cvsroot/a", :module_name => "b").should eq(:pserver)
    CvsAdapter.new(:url => ":ext:foo:@foo.com:/cvsroot/a", :module_name => "b").should eq(:ext)
    CvsAdapter.new(:url => ":pserver:ext:@foo.com:/cvsroot/a", :module_name => "b").should eq(:pserver)
  end

  it "log_encoding" do
    with_cvs_repository("cvs", "invalid_utf8") do |cvs|
      cvs.log.valid_encoding?.should eq(true)
    end
  end

  it "tags" do
    with_cvs_repository("cvs", "simple") do |cvs|
      cvs.tags.should eq([["simple_release_tag", "1.1.1.1"], ["simple_vendor_tag", "1.1.1"]])
    end
  end

  it "export_tag" do
    with_cvs_repository("cvs", "simple") do |cvs|
      OhlohScm::ScratchDir.new do |dir|
        cvs.export_tag(dir, "simple_release_tag")

        Dir.entries(dir).sort.should eq([".","..","foo.rb"])
      end
    end
  end
end
