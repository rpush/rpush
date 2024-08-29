# Specify here only version constraints that differ from
# `rpush.gemspec`.
#
# > The dependencies in your Appraisals file are combined with dependencies in
# > your Gemfile, so you don't need to repeat anything that's the same for each
# > appraisal. If something is specified in both the Gemfile and an appraisal,
# > the version from the appraisal takes precedence.
# > https://github.com/thoughtbot/appraisal

appraise "rails-6.0" do
  gem "activesupport", "~> 6.0.0"
  # https://gist.github.com/yahonda/2776d8d7b6ea7045359f38c10449937b#rails-60z
  # https://gist.github.com/yahonda/2776d8d7b6ea7045359f38c10449937b#psych-4-support
  gem "psych", "~> 3.0"

  group :development do
    gem "rails", "~> 6.0.0"
  end
end

appraise "rails-6.1" do
  gem "activesupport", "~> 6.1.0"

  group :development do
    gem "rails", "~> 6.1.0"
  end
end

appraise "rails-7.0" do
  gem "activesupport", "~> 7.0.0"

  group :development do
    gem "rails", "~> 7.0.0"
  end
end
