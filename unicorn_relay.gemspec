# -*- encoding: utf-8 -*-
# stub: unicorn_relay 0.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "unicorn_relay".freeze
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Florian Frank".freeze]
  s.date = "2016-10-12"
  s.description = "Allow controlling unicorn via supervise by relaying signals to it".freeze
  s.email = "flori@ping.de".freeze
  s.executables = ["unicorn_relay".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "lib/unicorn_relay.rb".freeze, "lib/unicorn_relay/forker.rb".freeze, "lib/unicorn_relay/teardown.rb".freeze, "lib/unicorn_relay/version.rb".freeze]
  s.files = [".gitignore".freeze, ".rspec".freeze, ".travis.yml".freeze, ".utilsrc".freeze, "Gemfile".freeze, "README.md".freeze, "Rakefile".freeze, "VERSION".freeze, "bin/unicorn_relay".freeze, "bin/unocorn".freeze, "lib/unicorn_relay.rb".freeze, "lib/unicorn_relay/forker.rb".freeze, "lib/unicorn_relay/teardown.rb".freeze, "lib/unicorn_relay/version.rb".freeze, "spec/forker_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/teardown_spec.rb".freeze, "unicorn_relay.gemspec".freeze]
  s.homepage = "http://flori.github.com/unicorn_relay".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rdoc_options = ["--title".freeze, "UnicornRelay -- More Math in Ruby".freeze, "--main".freeze, "README.md".freeze]
  s.rubygems_version = "2.6.7".freeze
  s.summary = "Allow controlling unicorn via supervise".freeze
  s.test_files = ["spec/forker_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/teardown_spec.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<gem_hadar>.freeze, ["~> 1.9.1"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_development_dependency(%q<yard>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<tins>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<mize>.freeze, [">= 0"])
    else
      s.add_dependency(%q<gem_hadar>.freeze, ["~> 1.9.1"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<simplecov>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_dependency(%q<yard>.freeze, [">= 0"])
      s.add_dependency(%q<tins>.freeze, ["~> 1.0"])
      s.add_dependency(%q<mize>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<gem_hadar>.freeze, ["~> 1.9.1"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<yard>.freeze, [">= 0"])
    s.add_dependency(%q<tins>.freeze, ["~> 1.0"])
    s.add_dependency(%q<mize>.freeze, [">= 0"])
  end
end
