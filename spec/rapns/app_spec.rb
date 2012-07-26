require "spec_helper"

describe Rapns::App do
  it 'expects subclasses to implement new_runner' do
    expect { Rapns::App.new.new_runner }.to raise_error(NotImplementedError)
  end
end
