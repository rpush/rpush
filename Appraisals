# Specify here only version constraints that differ from
# `rpush.gemspec`.
#
# > The dependencies in your Appraisals file are combined with dependencies in
# > your Gemfile, so you don't need to repeat anything that's the same for each
# > appraisal. If something is specified in both the Gemfile and an appraisal,
# > the version from the appraisal takes precedence.
# > https://github.com/thoughtbot/appraisal

appraise "rails-4.2" do
  gem "rails", "~> 4.2"
  gem "mongoid", "~> 5"
  gem "mongoid-autoinc", "~> 5"
end

appraise "rails-5.0" do
  gem "rails", "~> 5.0"
  gem "mongoid", ">= 6.0", "< 6.2"
  gem "mongoid-autoinc", ">= 6.0", "< 6.2"
end

appraise "rails-5.1" do
  gem "rails", "5.1.1"
  gem "mongoid", ">= 6.2"
  gem "mongoid-autoinc", ">= 6.0.2"
end
