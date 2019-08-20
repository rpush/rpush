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
    # Rails 4.2 doesn't support pg 1.0
    gem "pg", "< 1.0"
  end
end

appraise "rails-5.0" do
  gem "activesupport", ">= 5.0", "< 5.1"

  group :development do
    gem "rails", ">= 5.0", "< 5.1"
    # Supposedly Rails 5-stable already supports pg 1.0 but hasn't had a
    # release yet.
    # https://github.com/rails/rails/pull/31671#issuecomment-357605227
    gem "pg", "< 1.0"
  end
end

appraise "rails-5.1" do
  gem "activesupport", ">= 5.1", "< 5.2"

  group :development do
    gem "rails", ">= 5.1", "< 5.2"
  end
end

appraise "rails-5.2" do
  gem "activesupport", ">= 5.2.0", "< 5.3"

  group :development do
    gem "rails", ">= 5.2.0", "< 5.3"
  end
end

appraise "rails-6.0" do
  gem 'activesupport', '~> 6.0.0'

  group :development do
    gem 'rails', '~> 6.0.0'
  end
end
