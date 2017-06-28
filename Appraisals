# Specify here only version constraints that differ from
# `rpush.gemspec`.
#
# > The dependencies in your Appraisals file are combined with dependencies in
# > your Gemfile, so you don't need to repeat anything that's the same for each
# > appraisal. If something is specified in both the Gemfile and an appraisal,
# > the version from the appraisal takes precedence.
# > https://github.com/thoughtbot/appraisal

appraise "rails-4.2" do
  gem "activesupport", "~> 4.2"

  group :development do
    gem "rails", "~> 4.2"
    gem "rpush-mongoid", "0.1.0"
  end
end

appraise "rails-5.0" do
  gem "activesupport", ">= 5.0", "< 5.1"

  group :development do
    gem "rails", ">= 5.0", "< 5.1"
  end
end

appraise "rails-5.1" do
  gem "activesupport", ">= 5.1"

  group :development do
    gem "rails", ">= 5.1"
  end
end
