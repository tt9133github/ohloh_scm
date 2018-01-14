require "../spec_helper"

describe "SvnMisc" do

  it "export" do
    with_svn_repository("svn") do |svn|
      OhlohScm::ScratchDir.new do |dir|
        svn.export(dir)
        Dir.entries(dir).sort.should eq([".","..","branches","tags","trunk"])
      end
    end
  end

  it "export_tag" do
    with_svn_repository("svn", "trunk") do |source_scm|
      OhlohScm::ScratchDir.new do |svn_working_folder|
        OhlohScm::ScratchDir.new do |dir|
          folder_name = source_scm.root.slice(/[^\/]+\/?\Z/)
          system "cd #{ svn_working_folder } && svn co #{ source_scm.root } && cd #{ folder_name } &&
                  mkdir -p #{ source_scm.root.gsub(/^file:../, "") }/db/transactions
                  svn copy trunk tags/2.0 && svn commit -m 'v2.0' && svn update"

          source_scm.export_tag(dir, "2.0")

          Dir.entries(dir).sort.should eq([".","..","COPYING","README","helloworld.c", "makefile"])
        end
      end
    end
  end

  it "ls_tree" do
    with_svn_repository("svn") do |svn|
      svn.ls_tree(2).sort.should eq(["branches/","tags/","trunk/","trunk/helloworld.c","trunk/makefile"])
    end
  end

  it "path" do
    SvnAdapter.new({:url => "http://svn.collab.net/repos/svn/trunk"}).path.should be_falsey
    SvnAdapter.new({:url => "svn://svn.collab.net/repos/svn/trunk"}).path.should be_falsey
    SvnAdapter.new({:url => "file:///foo/bar"}).path.should eq("/foo/bar")
    SvnAdapter.new({:url => "file://foo/bar"}).path.should eq("foo/bar")
    SvnAdapter.new({:url => "svn+ssh://server/foo/bar"}).path.should eq("/foo/bar")
  end

  it "hostname" do
    SvnAdapter.new({:url => "http://svn.collab.net/repos/svn/trunk"}).hostname.should be_falsey
    SvnAdapter.new({:url => "svn://svn.collab.net/repos/svn/trunk"}).hostname.should be_falsey
    SvnAdapter.new({:url => "file:///foo/bar"}).hostname.should be_falsey
    SvnAdapter.new({:url => "svn+ssh://server/foo/bar"}).hostname.should eq("server")
  end

  it "info" do
    with_svn_repository("svn") do |svn|
      svn.root.should eq(svn.url)
      svn.uuid.should eq("6a9cefd4-a008-4d2a-a89b-d77e99cd6eb1")
      svn.node_kind.should eq("directory")

      svn.node_kind("trunk/helloworld.c",1).should eq("file")
    end
  end

  it "ls" do
    with_svn_repository("svn") do |svn|
      svn.ls.should eq(["branches/", "tags/", "trunk/"])
      svn.ls("trunk").should eq(["COPYING","README","helloworld.c","makefile"])
      svn.ls("trunk", 1).should eq(["helloworld.c"])

      svn.recurse_files(nil, 1).should eq(["trunk/helloworld.c"])
      svn.recurse_files("/trunk", 1).should eq(["helloworld.c"])
    end
  end

  it "is_directory" do
    with_svn_repository("svn") do |svn|
      svn.is_directory?("trunk").should be_truthy
      svn.is_directory?("trunk/helloworld.c").should be_falsey
      svn.is_directory?("invalid/path").should be_falsey
    end
  end

  it "restrict_url_to_trunk_descend_no_further" do
    with_svn_repository("deep_svn") do |svn|
      svn.url.should eq(svn.root)
      svn.branch_name.should eq("")

      svn.restrict_url_to_trunk

      svn.url.should eq(svn.root + "/trunk")
      svn.branch_name.should eq("/trunk")
    end
  end

  it "restrict_url_to_trunk" do
    with_svn_repository("svn") do |svn|
      svn.url.should eq(svn.root)
      svn.branch_name.should eq("")

      svn.restrict_url_to_trunk

      svn.url.should eq(svn.root + "/trunk")
      svn.branch_name.should eq("/trunk")
    end
  end

  it "tags" do
    with_svn_repository("svn", "trunk") do |source_scm|
      OhlohScm::ScratchDir.new do |svn_working_folder|
        folder_name = source_scm.root.slice(/[^\/]+\/?\Z/)
        system "cd #{ svn_working_folder } && svn co #{ source_scm.root } && cd #{ folder_name } &&
                mkdir -p #{ source_scm.root.gsub(/^file:../, "") }/db/transactions
                svn copy trunk tags/2.0 && svn commit -m \"v2.0\" && svn update"

        source_scm.tags.first[0..1].should eq(["2.0", "6"])
        # Avoid millisecond comparision.
        source_scm.tags.first[-1].strftime("%F %R").should eq(Time.now.strftime("%F %R"))
      end
    end
  end

  it "tags_with_whitespaces" do
    with_svn_repository("svn", "trunk") do |source_scm|
      OhlohScm::ScratchDir.new do |svn_working_folder|
        folder_name = source_scm.root.slice(/[^\/]+\/?\Z/)
        system %(cd #{ svn_working_folder } && svn co #{ source_scm.root } && cd #{ folder_name } &&
                mkdir -p #{ source_scm.root.gsub(/^file:../, "") }/db/transactions
                svn copy trunk tags/"HL7 engine" && svn commit -m "v2.0" && svn update && svn propset svn:date --revprop -r "HEAD" 2016-02-12T00:44:04.921324Z)

        source_scm.tags.first[0..1].should eq(["HL7 engine", "6"])
        # Avoid millisecond comparision.
        source_scm.tags.first[-1].strftime("%F").should eq("2016-02-12")
      end
    end
  end

  it "tags_with_non_tagged_repository" do
    with_svn_repository("svn") do |svn|
      Array(Nil).new.should eq(svn.tags)
    end
  end
end
