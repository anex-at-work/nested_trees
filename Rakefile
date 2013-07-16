require 'rake/testtask'
require 'bundler'
Bundler::GemHelper.install_tasks

desc "Run tests"
task :test do
  Dir['test/**/*.rb'].each do |t|
    load t
  end
end

task :default => :test