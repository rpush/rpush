require 'unit_spec_helper'

describe Rpush::Daemon::Batch do
  let(:notification1) { double(:notification1, id: 1) }
  let(:notification2) { double(:notification2, id: 2) }
  let(:batch) { Rpush::Daemon::Batch.new([notification1, notification2]) }
  let(:store) { double.as_null_object }
  let(:time) { Time.now }

  before do
    Time.stub(now: time)
    Rpush::Daemon.stub(store: store)
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

  describe 'mark_delivered' do
    it 'marks the notification as delivered immediately without persisting' do
      store.should_receive(:mark_delivered).with(notification1, time, persist: false)
      batch.mark_delivered(notification1)
    end

    it 'defers persisting' do
      batch.mark_delivered(notification1)
      batch.delivered.should eq [notification1]
    end
  end

  describe 'mark_all_delivered' do
    it 'marks the notifications as delivered immediately without persisting' do
      store.should_receive(:mark_delivered).with(notification1, time, persist: false)
      store.should_receive(:mark_delivered).with(notification2, time, persist: false)
      batch.mark_all_delivered
    end

    it 'defers persisting' do
      batch.mark_all_delivered
      batch.delivered.should eq [notification1, notification2]
    end
  end

  describe 'mark_failed' do
    it 'marks the notification as failed without persisting' do
      store.should_receive(:mark_failed).with(notification1, 1, 'an error', time, persist: false)
      batch.mark_failed(notification1, 1, 'an error')
    end

    it 'defers persisting' do
      batch.mark_failed(notification1, 1, 'an error')
      batch.failed.should eq([1, 'an error'] => [notification1])
    end
  end

  describe 'mark_failed' do
    it 'marks the notification as failed without persisting' do
      store.should_receive(:mark_failed).with(notification1, 1, 'an error', time, persist: false)
      store.should_receive(:mark_failed).with(notification2, 1, 'an error', time, persist: false)
      batch.mark_all_failed(1, 'an error')
    end

    it 'defers persisting' do
      batch.mark_all_failed(1, 'an error')
      batch.failed.should eq([1, 'an error'] => [notification1, notification2])
    end
  end

  describe 'mark_retryable' do
    it 'marks the notification as retryable without persisting' do
      store.should_receive(:mark_retryable).with(notification1, time, persist: false)
      batch.mark_retryable(notification1, time)
    end

    it 'defers persisting' do
      batch.mark_retryable(notification1, time)
      batch.retryable.should eq(time => [notification1])
    end
  end

  describe 'complete' do
    before do
      Rpush.stub(logger: double.as_null_object)
      batch.stub(:reflect)
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
      def complete
        [notification1, notification2].each do |n|
          batch.mark_delivered(n)
          batch.notification_processed
        end
      end

      it 'marks the batch as delivered' do
        store.should_receive(:mark_batch_delivered).with([notification1, notification2])
        complete
      end

      it 'reflects the notifications were delivered' do
        batch.should_receive(:reflect).with(:notification_delivered, notification1)
        batch.should_receive(:reflect).with(:notification_delivered, notification2)
        complete
      end
    end

    describe 'failed' do
      def complete
        [notification1, notification2].each do |n|
          batch.mark_failed(n, 1, 'an error')
          batch.notification_processed
        end
      end

      it 'marks the batch as failed' do
        store.should_receive(:mark_batch_failed).with([notification1, notification2], 1, 'an error')
        complete
      end

      it 'reflects the notifications failed' do
        batch.should_receive(:reflect).with(:notification_failed, notification1)
        batch.should_receive(:reflect).with(:notification_failed, notification2)
        complete
      end
    end

    describe 'retryable' do
      def complete
        [notification1, notification2].each do |n|
          batch.mark_retryable(n, time)
          batch.notification_processed
        end
      end

      it 'marks the batch as retryable' do
        store.should_receive(:mark_batch_retryable).with([notification1, notification2], time)
        complete
      end

      it 'reflects the notifications will be retried' do
        batch.should_receive(:reflect).with(:notification_will_retry, notification1)
        batch.should_receive(:reflect).with(:notification_will_retry, notification2)
        complete
      end
    end
  end
end
