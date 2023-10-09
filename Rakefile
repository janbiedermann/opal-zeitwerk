require_relative 'lib/opal/zeitwerk/version'

task :push do
  system("git push github")
  system("git push trabant")
end

task :push_packages do
  Rake::Task['push_packages_to_rubygems'].invoke
  Rake::Task['push_packages_to_github'].invoke
end

task :push_packages_to_rubygems do
  system("gem push opal-zeitwerk-#{Opal::Zeitwerk::VERSION}.gem")
end

task :push_packages_to_github do
  system("gem push --key github --host https://rubygems.pkg.github.com/isomorfeus opal-zeitwerk-#{Opal::Zeitwerk::VERSION}.gem")
end
