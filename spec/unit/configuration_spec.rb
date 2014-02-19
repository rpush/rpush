require 'unit_spec_helper'

describe Rpush do
  let(:config) { double }

  before { Rpush.stub(:config => config) }

  it 'can yields a config block' do
    expect { |b| Rpush.configure(&b) }.to yield_with_args(config)
  end
end

describe Rpush::Configuration do
  let(:config) do
    Rpush::Deprecation.muted do
      Rpush::Configuration.new
    end
  end

  it 'can be updated' do
    Rpush::Deprecation.muted do
      new_config = Rpush::Configuration.new
      new_config.batch_size = 200
      expect { config.update(new_config) }.to change(config, :batch_size).to(200)
    end
  end

  it 'sets the pid_file relative if not absolute' do
    Rails.stub(:root => '/rails')
    config.pid_file = 'tmp/rpush.pid'
    config.pid_file.should eq '/rails/tmp/rpush.pid'
  end

  it 'does not alter an absolute pid_file path' do
    config.pid_file = '/tmp/rpush.pid'
    config.pid_file.should eq '/tmp/rpush.pid'
  end

  it 'does not allow foreground to be set to false if the platform is JRuby' do
    config.foreground = true
    Rpush.stub(:jruby? => true)
    config.foreground = false
    config.foreground.should be_true
  end
end
