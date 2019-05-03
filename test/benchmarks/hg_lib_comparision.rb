# NOTE: Setup before running benchmark
# cd test/repositories
# tar xzf hg_large.tgz && cd hg_large
# bash create-large-file.sh 14 # Create a file as per given factor # 14=19MB # 15=38MB # 16=76MB # 17=151MB
# hg add && hg commit -m 'temp'
# cd ../../../
# ruby test/benchmarks/hg_lib_comparision.rb
# hg rollback # revert last commit to try different file sizes.

require_relative '../../lib/ohloh_scm'
require 'benchmark'

repo_path = File.expand_path('../repositories/hg_large', __dir__)

puts "Benchmarks for `cat_file`"
logger = Logger.new(STDERR)
logger.level = Logger::WARN
OhlohScm::Adapters::HgAdapter.logger = logger

hg = OhlohScm::Adapters::HgAdapter.new(url: repo_path)
hglib = OhlohScm::Adapters::HglibAdapter.new(url: repo_path)
commit = OhlohScm::Commit.new(token: '1')
diff = OhlohScm::Diff.new(path: 'large.php')

puts `du -sh #{repo_path}/large.php`

Benchmark.bmbm 20 do |reporter|
  reporter.report('HgAdapter[bash api]     ') do
    hg.cat_file(commit, diff)
  end

  reporter.report('HglibAdapter[python api]') do
    hglib.cat_file(commit, diff)
  end
end
