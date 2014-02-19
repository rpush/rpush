require 'unit_spec_helper'

describe Rpush::Daemon::Delivery do

  class DeliverySpecDelivery < Rpush::Daemon::Delivery
    def initialize(batch)
      @batch = batch
    end
  end

  let(:now) { Time.parse("2014-10-14 00:00:00") }
  let(:batch) { double(Rpush::Daemon::Batch) }
  let(:delivery) { DeliverySpecDelivery.new(batch) }
  let(:notification) { Rpush::Apns::Notification.new }

  before { Time.stub(now: now) }

  describe 'mark_retryable' do

    it 'does not retry a notification with an expired fail_after' do
      batch.should_receive(:mark_failed).with(notification, nil, "Notification failed to be delivered before 2014-10-13 23:00:00.")
      notification.fail_after = Time.now - 1.hour
      delivery.mark_retryable(notification, Time.now + 1.hour)
    end

    it 'retries the notification if does not have a fail_after time' do
      batch.should_receive(:mark_retryable)
      notification.fail_after = nil
      delivery.mark_retryable(notification, Time.now + 1.hour)
    end

    it 'retries the notification if the fail_after time has not been reached' do
      batch.should_receive(:mark_retryable)
      notification.fail_after = Time.now + 1.hour
      delivery.mark_retryable(notification, Time.now + 1.hour)
    end
  end
end
