require 'rake'
require 'rake/clean'
require 'rake/testtask'

desc 'Run tests in test/unit directory'
Rake::TestTask.new(:test) do |t|
  t.libs << ['test']
  t.test_files = FileList['test/unit/**/*_test.rb']
  # t.verbose = true
end

task :default => :test

