# NOTE: Setup before running benchmark
# cd test/repositories
# tar xzf bzr_large.tgz && cd bzr_large
# bash create-large-file.sh 14 # Create a file as per given factor # 14=19MB # 15=38MB # 16=76MB # 17=151MB
# bzr add && bzr commit -m 'temp'
# cd ../../../
# ruby test/benchmarks/bzr_lib_comparision.rb
# bzr uncommit # revert last commit to try different file sizes.

require_relative '../../lib/ohloh_scm'
require 'benchmark'

repo_path = File.expand_path('../repositories/bzr_large', __dir__)

puts "Benchmarks for `cat_file`"
logger = Logger.new(STDERR)
logger.level = Logger::WARN
OhlohScm::Adapters::BzrAdapter.logger = logger

bzr = OhlohScm::Adapters::BzrAdapter.new(url: repo_path)
bzrlib = OhlohScm::Adapters::BzrlibAdapter.new(url: repo_path)
commit = OhlohScm::Commit.new(token: '1')
diff = OhlohScm::Diff.new(path: 'large.php')

puts `du -sh #{repo_path}/large.php`

Benchmark.bmbm 20 do |reporter|
  reporter.report('BzrAdapter[bash api]     ') do
    bzr.cat_file(commit, diff)
  end

  reporter.report('BzrlibAdapter[python api]') do
    bzrlib.cat_file(commit, diff)
  end
end
