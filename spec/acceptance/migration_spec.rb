require 'acceptance_spec_helper'

describe "generating migrations in a new app" do
  before { setup_rails }

  it 'it applies the migrations' do
    generate.should be_true
    migrate.should be_true
  end
end