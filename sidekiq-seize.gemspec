# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name                  = 'sidekiq-seize'
  gem.version               = '0.4.0'
  gem.authors               = ['Rajat Goyal']
  gem.email                 = ['rajat@synaptic.com']
  gem.summary               = 'Sidekiq middleware to silent errors and send only on dead'
  gem.description           = 'Sidekiq middleware that allows capturing exceptions silently until the last retry.'
  gem.license               = 'MIT'
  gem.executables           = []
  gem.files                 = `git ls-files`.split("\n")
  gem.test_files            = `git ls-files -- spec/*`.split("\n")
  gem.require_paths         = ['lib']
  gem.required_ruby_version = '>= 2.2.2'

  gem.add_runtime_dependency 'sidekiq', '~> 5.0', '>= 5.0.0'
  gem.add_development_dependency 'rspec', '~> 3.6', '>= 3.6.0'
  gem.add_development_dependency 'byebug'
end
