require 'unit_spec_helper'

describe Rapns::Daemon::Batch do
  let(:notification1) { double(:id => 1) }
  let(:notification2) { double(:id => 2) }
  let(:batch) { Rapns::Daemon::Batch.new([notification1, notification2]) }
  let(:store) { double.as_null_object }

  before do
    Rapns::Daemon.stub(:store => store)
  end

  it 'exposes the notifications' do
    batch.notifications.should eq [notification1, notification2]
  end

  it 'exposes the number notifications' do
    batch.num_notifications.should eq 2
  end

  it 'exposes the number notifications processed' do
    batch.num_processed.should eq 0
  end

  it 'increments the processed notifications count' do
    expect { batch.notification_processed }.to change(batch, :num_processed).to(1)
  end

  it 'completes the batch when all notifications have been processed' do
    batch.should_receive(:complete)
    2.times { batch.notification_processed }
  end

  it 'can be described' do
    batch.describe.should eq '1, 2'
  end

  describe 'mark_delivered' do
    it 'marks the notification as delivered immediately if batching is disabled' do
      Rapns.config.batch_storage_updates = false
      store.should_receive(:mark_delivered).with(notification1)
      batch.mark_delivered(notification1)
    end

    it 'defers marking the notification as delivered until the batch is complete' do
      Rapns.config.batch_storage_updates = true
      batch.mark_delivered(notification1)
      batch.delivered.should eq [notification1]
    end
  end

  describe 'mark_failed' do
    it 'marks the notification as failed immediately if batching is disabled' do
      Rapns.config.batch_storage_updates = false
      store.should_receive(:mark_failed).with(notification1, 1, 'an error')
      batch.mark_failed(notification1, 1, 'an error')
    end

    it 'defers marking the notification as failed until the batch is complete' do
      Rapns.config.batch_storage_updates = true
      batch.mark_failed(notification1, 1, 'an error')
      batch.failed.should eq({[1, 'an error'] => [notification1]})
    end
  end

  describe 'mark_retryable' do
    let(:time) { Time.now }

    it 'marks the notification as retryable immediately if batching is disabled' do
      Rapns.config.batch_storage_updates = false
      store.should_receive(:mark_retryable).with(notification1, time)
      batch.mark_retryable(notification1, time)
    end

    it 'defers marking the notification as retryable until the batch is complete' do
      Rapns.config.batch_storage_updates = true
      batch.mark_retryable(notification1, time)
      batch.retryable.should eq({time => [notification1]})
    end
  end

  describe 'complete' do
    before do
      Rapns.config.batch_storage_updates = true
      Rapns.stub(:logger => double.as_null_object)
    end

    it 'clears the notifications' do
      expect do
        2.times { batch.notification_processed }
      end.to change(batch, :notifications).to([])
    end

    it 'identifies as complete' do
      expect do
        2.times { batch.notification_processed }
      end.to change(batch, :complete?).to(be_true)
    end

    it 'reflects errors raised during completion' do
      e = StandardError.new
      batch.stub(:complete_delivered).and_raise(e)
      batch.should_receive(:reflect).with(:error, e)
      2.times { batch.notification_processed }
    end

    describe 'delivered' do
      it 'marks the batch as delivered' do
        store.should_receive(:mark_batch_delivered).with([notification1, notification2])
        [notification1, notification2].each do |n|
          batch.mark_delivered(n)
          batch.notification_processed
        end
      end

      it 'clears the delivered notifications' do
        [notification1, notification2].each { |n| batch.mark_delivered(n) }
        expect do
          2.times { batch.notification_processed }
        end.to change(batch, :delivered).to([])
      end
    end

    describe 'failed' do
      it 'marks the batch as failed' do
        store.should_receive(:mark_batch_failed).with([notification1, notification2], 1, 'an error')
        [notification1, notification2].each do |n|
          batch.mark_failed(n, 1, 'an error')
          batch.notification_processed
        end
      end

      it 'clears the failed notifications' do
        [notification1, notification2].each { |n| batch.mark_failed(n, 1, 'an error') }
        expect do
          2.times { batch.notification_processed }
        end.to change(batch, :failed).to({})
      end
    end

    describe 'retryable' do
      let(:time) { Time.now }

      it 'marks the batch as retryable' do
        store.should_receive(:mark_batch_retryable).with([notification1, notification2], time)
        [notification1, notification2].each do |n|
          batch.mark_retryable(n, time)
          batch.notification_processed
        end
      end

      it 'clears the retyable notifications' do
        [notification1, notification2].each { |n| batch.mark_retryable(n, time) }
        expect do
          2.times { batch.notification_processed }
        end.to change(batch, :retryable).to({})
      end
    end
  end
end
