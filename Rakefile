require_relative 'lib/opal/zeitwerk/version'

# require 'rake/testtask'
#
# task :default => :test
#
# Rake::TestTask.new do |t|
#   t.test_files = Dir.glob('test/lib/**/test_*.rb')
#   t.libs << "test"
# end
#

task :push_ruby_packages do
  Rake::Task['push_ruby_packages_to_rubygems'].invoke
  Rake::Task['push_ruby_packages_to_github'].invok
end

task :push_ruby_packages_to_rubygems do
  system("gem push opal-zeitwerk-#{Opal::Zeitwerk::VERSION}.gem")
end

task :push_ruby_packages_to_github do
  system("gem push --key github --host https://rubygems.pkg.github.com/isomorfeus opal-zeitwerk-#{Opal::Zeitwerk::VERSION}.gem")
end
