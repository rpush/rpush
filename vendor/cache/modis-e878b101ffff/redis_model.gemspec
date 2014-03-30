# -*- encoding: utf-8 -*-
# stub: modis 0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "modis"
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Ian Leitch"]
  s.date = "2014-03-30"
  s.description = "ActiveModel + Redis"
  s.email = ["port001@gmail.com"]
  s.files = [".coveralls.yml", ".gitignore", ".ruby-gemset", ".ruby-version", ".travis.yml", "Gemfile", "LICENSE.txt", "README.md", "Rakefile", "lib/modis.rb", "lib/modis/attributes.rb", "lib/modis/configuration.rb", "lib/modis/errors.rb", "lib/modis/finders.rb", "lib/modis/model.rb", "lib/modis/persistence.rb", "lib/modis/transaction.rb", "lib/modis/version.rb", "lib/tasks/spec.rake", "redis_model.gemspec", "spec/attributes_spec.rb", "spec/errors_spec.rb", "spec/finders_spec.rb", "spec/persistence_spec.rb", "spec/spec_helper.rb", "spec/support/simplecov_helper.rb", "spec/support/simplecov_quality_formatter.rb", "spec/transaction_spec.rb", "spec/validations_spec.rb"]
  s.homepage = ""
  s.rubygems_version = "2.2.2"
  s.summary = "ActiveModel + Redis"
  s.test_files = ["spec/attributes_spec.rb", "spec/errors_spec.rb", "spec/finders_spec.rb", "spec/persistence_spec.rb", "spec/spec_helper.rb", "spec/support/simplecov_helper.rb", "spec/support/simplecov_quality_formatter.rb", "spec/transaction_spec.rb", "spec/validations_spec.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activemodel>, [">= 3.0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 3.0"])
      s.add_runtime_dependency(%q<redis>, [">= 3.0"])
    else
      s.add_dependency(%q<activemodel>, [">= 3.0"])
      s.add_dependency(%q<activesupport>, [">= 3.0"])
      s.add_dependency(%q<redis>, [">= 3.0"])
    end
  else
    s.add_dependency(%q<activemodel>, [">= 3.0"])
    s.add_dependency(%q<activesupport>, [">= 3.0"])
    s.add_dependency(%q<redis>, [">= 3.0"])
  end
end
