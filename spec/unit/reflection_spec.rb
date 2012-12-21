 require 'unit_spec_helper'

describe Rapns do
  it 'yields reflections for configuration' do
    did_yield = false
    Rapns.reflect { |on| did_yield = true }
    did_yield.should be_true
  end

  it 'returns all reflections' do
    Rapns.reflections.should be_kind_of(Rapns::Reflections)
  end
end

# :apns_feedback, :notification_enqueued, :notification_delivered,
#       :notification_failed, :notification_will_retry, :apns_connection_lost,
#       :error

describe Rapns::Reflections do
  it 'dispatches the given reflection' do
    did_yield = false
    Rapns.reflect do |on|
      on.error { did_yield = true }
    end
    Rapns.reflections.__dispatch(:error)
    did_yield.should be_true
  end

  it 'raises an error when trying to dispatch and unknown reflection' do
    expect do
      Rapns.reflections.__dispatch(:unknown)
    end.to raise_error(Rapns::Reflections::NoSuchReflectionError)
  end
end
