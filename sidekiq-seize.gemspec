# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name                  = 'sidekiq-seize'
  gem.version               = '1.0.0'
  gem.authors               = ['Rajat Goyal']
  gem.email                 = ['rajat@synaptic.com']
  gem.summary               = 'Sidekiq middleware to silent errors and send only on dead'
  gem.description           = 'idekiq middleware to silent errors and send only on dead '
  gem.license               = 'MIT'
  gem.executables           = []
  gem.files                 = `git ls-files`.split("\n")
  gem.test_files            = `git ls-files -- spec/*`.split("\n")
  gem.require_paths         = ['lib']
  gem.required_ruby_version = '>= 2.2.2'

  gem.add_dependency             'sidekiq', '>= 5.0.0'
  gem.add_development_dependency 'rspec', '>= 3.6.0'
end
