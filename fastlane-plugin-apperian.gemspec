# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/apperian/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-apperian'
  spec.version       = Fastlane::Apperian::VERSION
  spec.author        = %q{Tomi Blank}
  spec.email         = %q{tomiblank@gmail.com}

  spec.summary       = %q{Allows to upload your app file to Apperian}
  spec.homepage      = "https://github.com/tomiblank/fastlane-plugin-apperian"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # spec.add_dependency 'your-dependency', '~> 1.0.0'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'fastlane', '>= 1.106.2'
end
