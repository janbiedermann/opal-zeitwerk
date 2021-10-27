require_relative "lib/opal/zeitwerk/version"

Gem::Specification.new do |spec|
  spec.name        = "opal-zeitwerk"
  spec.summary     = "Opal constant autoloader using Zeitwerk"
  spec.description = <<-EOS
    A port of the Zeitwerk autoloader to Opal.
    Zeitwerk implements constant autoloading with Ruby semantics. Each gem
    and application may have their own independent autoloader, with its own
    configuration, inflector. Supports autoloading, preloading and eager loading.
  EOS

  spec.author   = "Jan Biedermann"
  spec.email    = 'jan@kursator.de'
  spec.license  = "MIT"
  spec.homepage = "https://github.com/isomorfeus/opal-zeitwerk"
  spec.metadata      = { "github_repo" => "ssh://github.com/isomorfeus/gems" }
  spec.files    = Dir["README.md", "MIT-LICENSE", "lib/**/*.rb", "opal/**/*.rb"]
  spec.version  = Opal::Zeitwerk::VERSION
  spec.require_paths = ['lib']

  spec.required_ruby_version = ">= 2.4.4"
  spec.add_dependency 'opal', '>= 1.3.0.rc1'
end
