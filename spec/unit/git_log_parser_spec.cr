require "../spec_helper"
require "date"

describe "GitStyledParser" do

  it "basic" do
    commits = Array(Nil).new

    helloworld = File.new(File.dirname(__FILE__) + "/../data/helloworld.log").read

    GitStyledParser.parse( helloworld ) do |commit|
      commits << commit
    end

    commits.should be_truthy
    commits.size.should eq(4)

    commits.each do |commit|
      # puts commit.inspect
      commit.token.length.should eq(40)

      # 00000000.... is ok for parent_sha1 (if we have no parent), but not for us!
      commit.token.should_not eq("0000000000000000000000000000000000000000")

      commit.author_name.should eq("robin")

      commit.diffs.each do |d|
        d.sha1.length.should eq(40)
        d.parent_sha1.length.should eq(40)
        d.path.length > 0.should be_truthy
        d.action =~ /[ACDMRTUXB]/.should be_truthy
      end
    end

    commits[0].author_date.should eq(Time.gm(2006,6,11,11,28,0))
    commits[1].author_date.should eq(Time.gm(2006,6,11,18,32,13))
    commits[2].author_date.should eq(Time.gm(2006,6,11, 9,34,17))

    commits[0].message.should eq("Initial Checkin")
    commits[1].message.should eq("added makefile")
    commits[2].message.should eq("added some documentation and licensing info")

    commits[0].diffs[0].path.should eq(".gitignore")
    commits[0].diffs[0].action.should eq("A")
    commits[0].diffs[1].path.should eq("helloworld.c")
    commits[0].diffs[1].action.should eq("A")
    commits[0].diffs[2].path.should eq("ohloh_token")
    commits[0].diffs[2].action.should eq("A")

    commits[1].diffs[0].path.should eq("makefile")
    commits[1].diffs[0].action.should eq("A")
    commits[1].diffs[1].path.should eq("ohloh_token")
    commits[1].diffs[1].action.should eq("M")

    commits[2].diffs[0].path.should eq("README")
    commits[2].diffs[0].action.should eq("A")
    commits[2].diffs[1].path.should eq("helloworld.c")
    commits[2].diffs[1].action.should eq("M")
    commits[2].diffs[2].path.should eq("ohloh_token")
    commits[2].diffs[2].action.should eq("M")
  end

  # If the filename includes non-ASCII characters, the filename is in double quotes.
  # The quotes must be stripped.
  it "filename_in_quotes" do
    log = <<-LOG
__BEGIN_COMMIT__
Commit: 0546fa73b6951be72956bf4c72c37255034d8bdc
Author: e2jk
Date: Tue, Mar 13 2007 17:08:49 -0700
__BEGIN_COMMENT__
Supprime le dossier des bibliotheques du projet
<unknown>
__END_COMMENT__
:100644 100644 8ffcfcbb647ab353e7e885fb3fd897eef719d64f e4eaafd3ed351461cef016bf606f0ce6af057380 M  "Cin\303\251 Library/Cin\303\251 Library.nsi"
  LOG

  commits = Array(Nil).new
  GitStyledParser.parse( log ) do |commit|
    commits << commit
  end
  commits[0].diffs[0].path.should eq("Cin\303\251 Library/Cin\303\251 Library.nsi")
end

# Not all commits include file diffs. Need to support that case.
it "commit_without_diffs" do
  log = <<-LOG
__BEGIN_COMMIT__
Commit: 9abc3b26e395ea5199362d6e19c705eb58842cd8
Author: troth
Date: Tue Feb 11 19:03:03 2003 +0000
__BEGIN_COMMENT__
Remove reference to avr-gcc in depend rule (cut & paste error).
<unknown>
__END_COMMENT__
:100644 100644 a35924054b56a3dd308ac92505b811bdfecee777 f4f4738ae0f49a56d97ba61d7feb09aa35d9e69d M  Makefile
__BEGIN_COMMIT__
Commit: 10ed46d82c279d090b664c48a88a95e7ad76de2f
Author: bdean
Date: Sun Feb 9 13:36:47 2003 +0000
__BEGIN_COMMENT__
Test commit in new public repository.  Before this time this repo
existed on a private system.  Commits made by 'bsd' on the old system
were made by Brian Dean (bdean on the current system).
__END_COMMENT__
__BEGIN_COMMIT__
Commit: 213c3220ff91eedda7323187fed0552e07069400
Author: bsd
Date: Sat Feb 8 04:20:39 2003 +0000
__BEGIN_COMMENT__
The last part of that last commit message should read:

All others - modify program description.

__END_COMMENT__
  LOG

  commits = Array(Nil).new
  GitStyledParser.parse( log ) do |commit|
    commits << commit
  end

  commits.should be_truthy
  commits.size.should eq(3)

  commits[0].message.should eq("Remove reference to avr-gcc in depend rule (cut & paste error).")
  commits[1].message.should eq("Test commit in new public repository.  Before this time this repo\n"+
                               "existed on a private system.  Commits made by \"bsd\" on the old system\n"+
                               "were made by Brian Dean (bdean on the current system).")

  commits[2].message.should eq("The last part of that last commit message should read:\n\nAll others - modify program description.\n")

  commits[0].diffs.size.should eq(1)
  commits[1].diffs.size.should eq(0)
  commits[2].diffs.size.should eq(0)
end

it "ignore_submodules" do
  log = <<-LOG
__BEGIN_COMMIT__
Commit: 9abc3b26e395ea5199362d6e19c705eb58842cd8
Author: troth
Date: Tue Feb 11 19:03:03 2003 +0000
__BEGIN_COMMENT__
Remove a submodule from the project
__END_COMMENT__
:160000 000000 f4f4738ae0f49a56d97ba61d7feb09aa35d9e69d 0000000000000000000000000000000000000000 D  submodule
__BEGIN_COMMIT__
Commit: 10ed46d82c279d090b664c48a88a95e7ad76de2f
Author: bdean
Date: Sun Feb 9 13:36:47 2003 +0000
__BEGIN_COMMENT__
Add a submodule to the project
__END_COMMENT__
:000000 160000 0000000000000000000000000000000000000000 f4f4738ae0f49a56d97ba61d7feb09aa35d9e69d A  submodule
  LOG

  commits = Array(Nil).new
  GitStyledParser.parse( log ) do |commit|
    commits << commit
  end

  commits.should be_truthy
  commits.size.should eq(2)

  commits.each do |commit|
    commit.diffs.size.should eq(0)
  end
end

it "use_email_when_names_are_missing" do
  log = <<-LOG
__BEGIN_COMMIT__
Commit: ea26f7280956f1112a8e68610cb9d6336a94585d
Author: mickeyl
AuthorEmail: mickeyl@openembedded.org
Date: Wed, 11 Jun 2008 00:37:47 +0000
__BEGIN_COMMENT__
fso-image: remove openmoko-sound-system2 in favour of pulseaudio-meta
<unknown>
__END_COMMENT__
:100644 100644 a5bd9a39acc1567586372b63f347fb4df4f20957 72e6bb0df6f21387b2a3e8e1519e4aefea6339a0 M      packages/images/fso-image.bb

__BEGIN_COMMIT__
Commit: fa3ee9d4cefc2db81adadf36da9cacbe92ce96f1
Author:
AuthorEmail: mickeyl@openembedded.org
Date: Wed, 11 Jun 2008 00:37:06 +0000
__BEGIN_COMMENT__
gst-plugins-good 0.10.7 add missing dependency to esound
<unknown>
__END_COMMENT__
:100644 100644 e84c4801f1d7acb0606e37a3a5b8c681182b3659 fb551f5176419f07b7901fb76493c8bb75de20ff M      packages/gstreamer/gst-plugins-good_0.10

    LOG

    commits = Array(Nil).new
    GitStyledParser.parse( log ) do |commit|
      commits << commit
    end

    commits.should be_truthy
    commits.size.should eq(2)

    commits.first.author_name.should eq("mickeyl") # Use name when present
    commits.last.author_name.should eq("mickeyl@openembedded.org") # Else use email
  end

  # Verifies OTWO-443
  it "empty_merge" do
    with_git_repository("git_with_empty_merge") do |git|
      git.commit_count.should eq(5)
      git.commits.size.should eq(5)
      c = git.verbose_commit("ff13970b54e5bc373abf932f0708b89e75c842b4")
      c.message.should eq("Merge branch 'feature'\n")
      c.diffs.size.should eq(0)
    end
  end
end
