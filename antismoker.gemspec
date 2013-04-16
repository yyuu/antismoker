# -*- encoding: utf-8 -*-
require File.expand_path('../lib/antismoker/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Yamashita Yuu"]
  gem.email         = ["yamashita@geishatokyo.com"]
  gem.description   = %q{Yet another HTTP smoke testing framework.}
  gem.summary       = %q{Yet another HTTP smoke testing framework.}
  gem.homepage      = "https://github.com/yyuu/antismoker"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "antismoker"
  gem.require_paths = ["lib"]
  gem.version       = AntiSmoker::VERSION

  gem.add_dependency("rake")
  gem.add_development_dependency("capistrano", "< 3")
  gem.add_development_dependency("capistrano-platform-resources", ">= 0.1.0")
  gem.add_development_dependency("capistrano-rbenv", ">= 0.1.0")
end
