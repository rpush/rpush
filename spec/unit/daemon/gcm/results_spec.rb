require 'unit_spec_helper'

RSpec.describe Rpush::Daemon::Gcm::Results do
  let(:results_data) do
    [
      { 'message_id' => 'm1' },
      { 'message_id' => 'm1', 'registration_id' => 'asd-x-canonical-2' },
      { 'error' => 'InvalidRegistration' },
      { 'error' => 'BadGateway' },
      { 'error' => 'The truth is out there' }
    ]
  end
  let(:registration_ids) { %w[asd asd2 fail fail2 fail3] }
  let(:failure_partitions) do
    { invalid: Rpush::Daemon::Gcm::Delivery::INVALID_REGISTRATION_ID_STATES,
      unavailable: Rpush::Daemon::Gcm::Delivery:: UNAVAILABLE_STATES }
  end
  let(:failure_result) do
    f = Rpush::Daemon::Gcm::Failures.new
    f << { registration_id: 'fail', index: 2, error: 'InvalidRegistration', invalid: true }
    f << { registration_id: 'fail2', index: 3, error: 'BadGateway', unavailable: true }
    f << { registration_id: 'fail3', index: 4, error: 'The truth is out there' }
    f
  end

  subject { described_class.new(results_data, registration_ids) }

  it 'returns failures with failure categories set within' do
    subject.process(failure_partitions)
    expect(subject.failures.map(&:itself)).to eq(failure_result.map(&:itself))
  end
end
