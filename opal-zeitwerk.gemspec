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
  spec.post_install_message = <<~TEXT

  opal-zeitwerk #{Opal::Zeitwerk::VERSION}:
    
    opal-zeitwerk currently requires the es6_modules_1_2 branch of opal, for the Gemfile:

    gem 'opal', github: 'janbiedermann/opal', branch: 'es6_modules_1_2'

    Commit 04c59bcb6ec124d021d464d12a45e7dae892456f from 7.1.2020 or later.

  TEXT

  spec.required_ruby_version = ">= 2.4.4"
  spec.add_dependency 'opal', '>= 1.2.0'
end
