# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git-contributors'

Gem::Specification.new do |spec|
  spec.name          = "git-contributors"
  spec.version       = GitContributors::VERSION
  spec.authors       = ["Dominik Richter"]
  spec.email         = ["dominik.richter@gmail.com"]
  spec.summary       = %q{Get all your projects' git contributors.}
  spec.description   = %q{Get all your projects' git contributors.}
  spec.homepage      = "https://github.com/hardening-io/git-contributors"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", "~> 10"

  spec.add_dependency 'diffy', '~> 3.0'
  spec.add_dependency 'inquirer', '~> 0'
  spec.add_dependency 'git-issues', '~> 0'
  spec.add_dependency 'rest-client', '~> 2'
  spec.add_dependency 'zlog', '~> 0'
  spec.add_dependency 'json', '~> 1.8'
end
