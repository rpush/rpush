require 'unit_spec_helper'
require 'rpush/daemon/store/active_record'

describe Rpush::Daemon::Store::ActiveRecord do
  let(:app) { Rpush::Client::ActiveRecord::Apns::App.create!(name: 'my_app', environment: 'development', certificate: TEST_CERT) }
  let(:notification) { Rpush::Client::ActiveRecord::Apns::Notification.create!(device_token: "a" * 64, app: app) }
  let(:store) { Rpush::Daemon::Store::ActiveRecord.new }
  let(:time) { Time.now.utc }
  let(:logger) { double(Rpush::Logger, error: nil) }

  before do
    Rpush.stub(logger: logger)
    Time.stub(now: time)
  end

  it 'reconnects after daemonize' do
    store.should_receive(:reconnect_database)
    store.after_daemonize
  end

  it 'can update a notification' do
    notification.should_receive(:save!)
    store.update_notification(notification)
  end

  it 'can update a app' do
    app.should_receive(:save!)
    store.update_app(app)
  end

  it 'can release a connection' do
    ActiveRecord::Base.connection_pool.should_receive(:release_connection)
    store.release_connection
  end

  it 'logs errors raised when trying to release the connection' do
    e = StandardError.new
    ActiveRecord::Base.connection_pool.stub(:release_connection).and_raise(e)
    Rpush.logger.should_receive(:error).with(e)
    store.release_connection
  end

  describe 'deliverable_notifications' do
    it 'checks for new notifications with the ability to reconnect the database' do
      store.should_receive(:with_database_reconnect_and_retry)
      store.deliverable_notifications(app)
    end

    it 'loads notifications in batches' do
      Rpush.config.batch_size = 5000
      Rpush.config.push = false
      relation = double.as_null_object
      relation.should_receive(:limit).with(5000)
      store.stub(ready_for_delivery_for_apps: relation)
      store.deliverable_notifications([app])
    end

    it 'does not load notification in batches if in push mode' do
      Rpush.config.push = true
      relation = double.as_null_object
      relation.should_not_receive(:limit)
      Rpush::Notification.stub(ready_for_delivery: relation)
      store.deliverable_notifications([app])
    end

    it 'loads an undelivered notification without deliver_after set' do
      notification.update_attributes!(delivered: false, deliver_after: nil)
      store.deliverable_notifications([app]).should eq [notification]
    end

    it 'loads an notification with a deliver_after time in the past' do
      notification.update_attributes!(delivered: false, deliver_after: 1.hour.ago)
      store.deliverable_notifications([app]).should eq [notification]
    end

    it 'does not load an notification with a deliver_after time in the future' do
      notification.update_attributes!(delivered: false, deliver_after: 1.hour.from_now)
      store.deliverable_notifications([app]).should be_empty
    end

    it 'does not load a previously delivered notification' do
      notification.update_attributes!(delivered: true, delivered_at: time)
      store.deliverable_notifications([app]).should be_empty
    end

    it "does not enqueue a notification that has previously failed delivery" do
      notification.update_attributes!(delivered: false, failed: true)
      store.deliverable_notifications([app]).should be_empty
    end

    it 'does not load notifications for apps that are still processing the previous batch' do
      notification
      store.deliverable_notifications([]).should be_empty
    end
  end

  describe 'mark_retryable' do
    it 'increments the retry count' do
      expect do
        store.mark_retryable(notification, time)
      end.to change(notification, :retries).by(1)
    end

    it 'sets the deliver after timestamp' do
      deliver_after = time + 10.seconds
      expect do
        store.mark_retryable(notification, deliver_after)
      end.to change(notification, :deliver_after).to(deliver_after)
    end

    it 'saves the notification without validation' do
      notification.should_receive(:save!).with(validate: false)
      store.mark_retryable(notification, time)
    end

    it 'does not save the notification if persist: false' do
      notification.should_not_receive(:save!)
      store.mark_retryable(notification, time, persist: false)
    end
  end

  describe 'mark_batch_retryable' do
    let(:deliver_after) { time + 10.seconds }

    it 'sets the attributes on the object for use in reflections' do
      store.mark_batch_retryable([notification], deliver_after)
      notification.deliver_after.should eq deliver_after
      notification.retries.should eq 1
    end

    it 'increments the retired count' do
      expect do
        store.mark_batch_retryable([notification], deliver_after)
        notification.reload
      end.to change(notification, :retries).by(1)
    end

    it 'sets the deliver after timestamp' do
      expect do
        store.mark_batch_retryable([notification], deliver_after)
        notification.reload
      end.to change { notification.deliver_after.try(:utc).to_s }.to(deliver_after.utc.to_s)
    end
  end

  describe 'mark_delivered' do
    it 'marks the notification as delivered' do
      expect do
        store.mark_delivered(notification, time)
      end.to change(notification, :delivered).to(true)
    end

    it 'sets the time the notification was delivered' do
      expect do
        store.mark_delivered(notification, time)
        notification.reload
      end.to change { notification.delivered_at.try(:utc).to_s }.to(time.to_s)
    end

    it 'saves the notification without validation' do
      notification.should_receive(:save!).with(validate: false)
      store.mark_delivered(notification, time)
    end

    it 'does not save the notification if persist: false' do
      notification.should_not_receive(:save!)
      store.mark_delivered(notification, time, persist: false)
    end
  end

  describe 'mark_batch_delivered' do
    it 'sets the attributes on the object for use in reflections' do
      store.mark_batch_delivered([notification])
      notification.delivered_at.should eq time
      notification.delivered.should be_true
    end

    it 'marks the notifications as delivered' do
      expect do
        store.mark_batch_delivered([notification])
        notification.reload
      end.to change(notification, :delivered).to(true)
    end

    it 'sets the time the notifications were delivered' do
      expect do
        store.mark_batch_delivered([notification])
        notification.reload
      end.to change { notification.delivered_at.try(:utc).to_s }.to(time.to_s)
    end
  end

  describe 'mark_failed' do
    it 'marks the notification as not delivered' do
      store.mark_failed(notification, nil, '', time)
      notification.delivered.should be_false
    end

    it 'marks the notification as failed' do
      expect do
        store.mark_failed(notification, nil, '', time)
        notification.reload
      end.to change(notification, :failed).to(true)
    end

    it 'sets the time the notification delivery failed' do
      expect do
        store.mark_failed(notification, nil, '', time)
        notification.reload
      end.to change { notification.failed_at.try(:utc).to_s }.to(time.to_s)
    end

    it 'sets the error code' do
      expect do
        store.mark_failed(notification, 42, '', time)
      end.to change(notification, :error_code).to(42)
    end

    it 'sets the error description' do
      expect do
        store.mark_failed(notification, 42, 'Weeee', time)
      end.to change(notification, :error_description).to('Weeee')
    end

    it 'saves the notification without validation' do
      notification.should_receive(:save!).with(validate: false)
      store.mark_failed(notification, nil, '', time)
    end

    it 'does not save the notification if persist: false' do
      notification.should_not_receive(:save!)
      store.mark_failed(notification, nil, '', time, persist: false)
    end
  end

  describe 'mark_batch_failed' do
    it 'sets the attributes on the object for use in reflections' do
      store.mark_batch_failed([notification], 123, 'an error')
      notification.failed_at.should eq time
      notification.delivered_at.should be_nil
      notification.delivered.should be_false
      notification.failed.should be_true
      notification.error_code.should eq 123
      notification.error_description.should eq 'an error'
    end

    it 'marks the notification as not delivered' do
      store.mark_batch_failed([notification], nil, '')
      notification.reload
      notification.delivered.should be_false
    end

    it 'marks the notification as failed' do
      expect do
        store.mark_batch_failed([notification], nil, '')
        notification.reload
      end.to change(notification, :failed).to(true)
    end

    it 'sets the time the notification delivery failed' do
      expect do
        store.mark_batch_failed([notification], nil, '')
        notification.reload
      end.to change { notification.failed_at.try(:utc).to_s }.to(time.to_s)
    end

    it 'sets the error code' do
      expect do
        store.mark_batch_failed([notification], 42, '')
        notification.reload
      end.to change(notification, :error_code).to(42)
    end

    it 'sets the error description' do
      expect do
        store.mark_batch_failed([notification], 42, 'Weeee')
        notification.reload
      end.to change(notification, :error_description).to('Weeee')
    end
  end

  describe 'create_apns_feedback' do
    it 'creates the Feedback record' do
      Rpush::Client::ActiveRecord::Apns::Feedback.should_receive(:create!).with(
        failed_at: time, device_token: 'ab' * 32, app: app)
      store.create_apns_feedback(time, 'ab' * 32, app)
    end
  end

  describe 'create_gcm_notification' do
    let(:data) { { data: true } }
    let(:attributes) { { device_token: 'ab' * 32 } }
    let(:registration_ids) { ['123', '456'] }
    let(:deliver_after) { time + 10.seconds }
    let(:args) { [attributes, data, registration_ids, deliver_after, app] }

    it 'sets the given attributes' do
      new_notification = store.create_gcm_notification(*args)
      new_notification.device_token.should eq 'ab' * 32
    end

    it 'sets the given data' do
      new_notification = store.create_gcm_notification(*args)
      new_notification.data['data'].should be_true
    end

    it 'sets the given registration IDs' do
      new_notification = store.create_gcm_notification(*args)
      new_notification.registration_ids.should eq registration_ids
    end

    it 'sets the deliver_after timestamp' do
      new_notification = store.create_gcm_notification(*args)
      new_notification.deliver_after.to_s.should eq deliver_after.to_s
    end

    it 'saves the new notification' do
      new_notification = store.create_gcm_notification(*args)
      new_notification.new_record?.should be_false
    end
  end

  describe 'create_adm_notification' do
    let(:data) { { data: true } }
    let(:attributes) { {app_id: app.id, collapse_key: 'ckey', delay_while_idle: true} }
    let(:registration_ids) { ['123', '456'] }
    let(:deliver_after) { time + 10.seconds }
    let(:args) { [attributes, data, registration_ids, deliver_after, app] }

    it 'sets the given attributes' do
      new_notification = store.create_adm_notification(*args)
      new_notification.app_id.should eq app.id
      new_notification.collapse_key.should eq 'ckey'
      new_notification.delay_while_idle.should be_true
    end

    it 'sets the given data' do
      new_notification = store.create_adm_notification(*args)
      new_notification.data['data'].should be_true
    end

    it 'sets the given registration IDs' do
      new_notification = store.create_adm_notification(*args)
      new_notification.registration_ids.should eq registration_ids
    end

    it 'sets the deliver_after timestamp' do
      new_notification = store.create_adm_notification(*args)
      new_notification.deliver_after.to_s.should eq deliver_after.to_s
    end

    it 'saves the new notification' do
      new_notification = store.create_adm_notification(*args)
      new_notification.new_record?.should be_false
    end
  end
end
