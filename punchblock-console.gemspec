# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "punchblock/console/version"

Gem::Specification.new do |s|
  s.name        = "punchblock-console"
  s.version     = PunchblockConsole::VERSION
  s.platform    = Gem::Platform::RUBY
  s.licenses    = ["MIT"]
  s.authors     = ["Ben Klang", "Ben Langfeld", "Jason Goecke"]
  s.email       = %q{punchblock@adhearsion.com}
  s.homepage    = %q{https://github.com/adhearsion/punchblock}
  s.summary     = "An interactive debugging console for Punchblock"
  s.description = "This gem provides a simple interactive console for troubleshooting and debugging the Rayo protocol via Punchblock."

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.7") if s.respond_to? :required_rubygems_version=

  s.add_runtime_dependency %q<punchblock>, [">= 0.5.0"]

  s.add_development_dependency %q<bundler>, ["~> 1.0.0"]
  s.add_development_dependency %q<rspec>, ["~> 2.3.0"]
  s.add_development_dependency %q<ci_reporter>, [">= 1.6.3"]
  s.add_development_dependency %q<yard>, ["~> 0.6.0"]
  s.add_development_dependency %q<rcov>, [">= 0"]
  s.add_development_dependency %q<rake>, [">= 0"]
  s.add_development_dependency %q<mocha>, [">= 0"]
  s.add_development_dependency %q<i18n>, [">= 0"]
end
