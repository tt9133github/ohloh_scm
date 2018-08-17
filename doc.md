h3. Bzr

|cat|bzr cat --name-from-revision -r @to_rev_param(revision) '@escape(path)'|
|verbose_commit|bzr xmllog --show-id -v --limit 1 -c revid:@token|
|open_log_file|bzr xmllog --show-id --forward --levels=1 -r revid:@after.. -v|
|open_log_file|bzr xmllog --show-id --forward --include-merges -r revid:@after.. -v|
|head_token|bzr log --limit 1 --show-id @url 2> /dev/null \| grep ^revision-id \| cut -f2 -d' '|
|parent_tokens|bzr log --long --show-id --limit 1 -c revid:@commit.token \| grep ^parent \| cut -f2 -d' '|
|ls_tree|bzr ls -V -r revid:@token|
|export_tag|bzr export -r tag:@tag_name @dest_dir|
|export|bzr export --format=dir -r revid:@token '@dest_dir'|
|tags|bzr tags|
|tags|bzr log -r @ rev  \| grep 'timestamp:' \| sed 's/timestamp://'|
|pull|mkdir -p '@url'|
|pull|rm -rf '@url'|
|pull|bzr branch '@from.url' '@url'|
|pull|bzr revert && bzr pull --overwrite '@from.url'|
|push|ssh @to.hostname 'mkdir -p @to.path'|
|push|scp -rpqB @bzr_path @to.hostname:@to.path|
|push|bzr revert && bzr push '@to.url'|

h3. Cvs

|open_log_file|cvsnt -d @url rlog -r@branch -d '@time' '@module_name' \| bin/string_encoder|
|open_log_file|cvsnt -d @url rlog -b -r1: -d '@time' '@module_name' \| bin/string_encoder|
|ls|cvsnt -q -d @url ls -e '@path'|
|log|cvsnt -d @url rlog -r@branch -d '@time' '@module_name' \| bin/string_encoder|
|log|cvsnt -d @url rlog -b -r1: -d '@time' '@module_name' \| bin/string_encoder|
|export_tag|cvsnt -d @url export -d'@dest_dir' -r @tag_name '@module_name'|
|checkout|cvsnt update -d -l -C @opt_D .|
|checkout|cvsnt update -d -l -C @opt_D '@d'|
|checkout|cvsnt update -d -R -C @opt_D|
|checkout|cvsnt -d @url checkout -D'@tokenZ' -A -d'@checkout_dir' '@module_name'|
|tags|cvs -Q -d @url rlog -h @module_name \| awk -F\"[.:]\" '/^\\t/&&$(NF-1)!=0'|

h3. Git

|cat|git cat-file -p @sha1|
|commit_all|git add .|
|commit_all|git commit -a -F @message_filename|
|anything_to_commit?|git status \| tail -1|
|init_db|mkdir -p '@url'|
|init_db|git init-db|
|commit_count|git rev-list --topo-order --reverse --first-parent @after..@upto \| wc -l|
|commit_tokens|git rev-list --topo-order --reverse --first-parent @after..@upto|
|open_log_file|git rev-list --topo-order --reverse --first-parent @after..@upto \| xargs -n 1 git whatchanged --root -m --abbrev=40 --max-count=1 --always --pretty=@format \| bin/string_encoder|
|head_token|git ls-remote --heads '@url' @branch_name|
|parent_tokens|git cat-file commit @commit.token \| grep ^parent \| cut -f 2 -d ' '|
|export|git archive @commit_id \| tar -C @ dest_dir  -x|
|ls_tree|git ls-tree -r @token \| cut -f 2 -d '\t'|
|get_commit_tree|git cat-file commit @token \| grep '^tree' \| cut -d ' ' -f 2|
|branches|git branch \| @ string_encoder |
|create_tracking_branch|git branch -f @name origin/@name|
|no_tags?|git tag \| head -1|
|tags|git tag --format='%(creatordate:iso-strict) %(objectname) %(refname)' \| sed 's/refs\\/tags\\///'|
|dereferenced_tag_strings|git show-ref --tags -d | grep '\\^{}' | sed 's/\\^{}//' | sed 's/refs\\/tags\\///'|
|patch_for_commit|git diff @token @commit.token|
|clone_or_fetch|mkdir -p '@url'|
|clone_or_fetch|rm -rf '@url'|
|clone_or_fetch|git clone -q -n '@source_scm.url' '@url' >/dev/null 2>&1|
|create_tracking_branch|git branch -f @name origin/@name|
|checkout|git clean -f -d -x|
|checkout|git reset --hard heads/@branch_name --|
|checkout|git checkout @branch_name --|
|clone_or_fetch|git fetch --update-head-ok '@source_scm.url' @branch_name:@branch_name|
|clean_up_disk|find . -maxdepth 1 -not -name .git -not -name . -print0 \| xargs -0 rm -rf --|
|push|git push '@to.url' @branch_name:@to.branch_name|
|push|ssh @to.hostname 'mkdir -p @to.path'|
|push|scp -rpqB @git_path @to.hostname:@to.path|
|read_token|git cat-file -p `git ls-tree HEAD @token_filename \| cut -c 13-51`|

h3. GitSvn

|cat|git show @revision:@file_path|
|git_commit|git svn find-rev r@commit.token|
|commit_count|{code}git svn log -r @after+1:@head_token+1 | grep -E -e '^r[0-9]+.*lines$' | wc -l{code}|
|source_scm_commit_count|bin/accept_svn_ssl_certificate svn info '@url'|
|open_log_file|{code}git svn log -v -r @after+1:@head_token+1 \| bin/string_encoder{code}|
|commit_tokens|{code}git svn log -r @after+1:@head_token+1 | grep '^r[0-9].*|' | awk -F'|' '{print $1}' | cut -c 2-{code}|
|head_token|{code}git svn log --limit=1 | grep '^r[0-9].*|' | awk -F'|' '{print $1}' | cut -c 2-{code}|
|clone|echo @password git svn clone --quiet '@source_scm.url' '@url'|
|fetch|git svn fetch|
|clean_up_disk|{code}find . -maxdepth 1 -not -name .git -not -name . -print0 | xargs -0 rm -rf --{code}|

h3. Hg

|cat|hg cat -r @rev @path.shellescape|
|commit_tokens|{code}hg log -f -v --follow-first -r @up_to:@after --template='{node}\\n'{code}|
|commit_tokens|{code}hg log -f -v -r '@upto:@after and (branch(@branch) or ancestors(@branch))' --template='{node}\\n'{code}|
|commits|hg log -f -v --follow-first -r @up_to:@after --style hg_style|
|commits|hg log -f -v -r '@upto:@after and (branch(@branch) or ancestors(@branch))' --style hg_style|
|verbose_commit|hg log -v -r @token --style hg_style \| bin/string_encoder|
|log|hg log -f -v --follow-first -r @up_to:@after \| bin/string_encoder|
|log|hg log -f -v -r '@upto:@after and (branch(@branch) or ancestors(@branch))' \| bin/string_encoder|
|open_log_file|hg log -f -v --follow-first -r @up_to:@after --style hg_style \| bin/string_encoder > logfile|
|open_log_file|hg log -f -v -r '@upto:@after and (branch(@branch) or ancestors(@branch))' --style hg_style \| bin/string_encoder > logfile|
|head_token|hg id --debug -i -q @url --rev @branch or :default|
|parent_tokens|{code}hg parents -r @token --template '{node}\\n'{code}|
|ls_tree|hg manifest -r @token \| bin/string_encoder|
|export|hg archive -r @token '@dest_dir'|
|tags|hg tags|
|tags|{code}hg log -r @rev | grep 'date:' | sed 's/date://'{code}|
|patch_for_commit|hg -R '@url' diff --git -r@token -r@commit.token|
|pull|mkdir -p '@url'|
|pull|rm -rf '@url'|
|pull|hg clone -U '@from.url' '@self.url'|
|pull|hg revert --all && hg pull -r @branch -u -y '@from.url'|
|push|ssh @to.hostname 'mkdir -p @to.path'|
|push|scp -rpqB @hg_path @to.hostname:@to.path|
|push|hg push -f -y '@to.url'|
