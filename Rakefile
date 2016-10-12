# vim: set filetype=ruby et sw=2 ts=2:

require 'gem_hadar'

GemHadar do
  name        'unicorn_relay'
  author      'Florian Frank'
  email       'flori@ping.de'
  homepage    "http://flori.github.com/#{name}"
  summary     'Allow controlling unicorn via supervise'
  description 'Allow controlling unicorn via supervise by relaying signals to it'
  test_dir    'spec'
  ignore      '.*.sw[pon]', 'pkg', 'Gemfile.lock', 'coverage', '.rvmrc',
    '.AppleDouble', 'tags', '.byebug_history', '.DS_Store', 'errors.lst',
    '.yardoc', 'yard'
  readme      'README.md'
  title       "#{name.camelize} -- More Math in Ruby"
  licenses    << 'Apache-2.0'
  executables << 'unicorn_relay'

  dependency  'tins', '~>1.0'
  dependency  'mize'
  development_dependency 'rake'
  development_dependency 'simplecov'
  development_dependency 'rspec'
  development_dependency 'yard'
end

task :default => :spec
