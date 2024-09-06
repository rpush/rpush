require 'unit_spec_helper'

shared_examples 'Rpush::Client::Fcm::App' do
  it 'should be valid if properly instantiated' do
    expect(subject).to be_valid
  end
end
