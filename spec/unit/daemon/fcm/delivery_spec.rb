require 'unit_spec_helper'

describe Rpush::Daemon::Fcm::Delivery do
  let(:app) { Rpush::Fcm::App.create!(name: 'MyApp', firebase_project_id: 'abc123', json_key:'{}') }
  let(:notification) { Rpush::Fcm::Notification.create!(app: app, device_token: 'xyz', deliver_after: Time.now) }
  let(:logger) { double(error: nil, info: nil, warn: nil) }
  let(:response) { double(code: 200, header: {}) }
  let(:http) { double(shutdown: nil, request: response) }
  let(:now) { Time.parse('2012-10-14 00:00:00') }
  let(:batch) { double(mark_failed: nil, mark_delivered: nil, mark_retryable: nil, notification_processed: nil) }
  let(:delivery) { Rpush::Daemon::Fcm::Delivery.new(app, http, notification, batch) }
  let(:store) { double(create_fcm_notification: double(id: 2)) }

  def perform
    delivery.perform
  end

  def perform_with_rescue
    expect { perform }.to raise_error(StandardError)
  end

  before do
    allow(delivery).to receive_messages(reflect: nil)
    allow(Rpush::Daemon).to receive_messages(store: store)
    allow(Time).to receive_messages(now: now)
    allow(Rpush).to receive_messages(logger: logger)
    allow_any_instance_of(Rpush::Daemon::Fcm::Delivery).to receive_messages(obtain_access_token: "access_token")
  end

  describe 'a 200 response' do
    before do
      allow(response).to receive_messages(code: 200)
      allow(response).to receive_messages(body: nil)
      allow(notification).to receive_messages(device_token: '1')
    end

    it 'reflects on ID which successfully received the notification' do
      expect(delivery).to receive(:reflect).with(:fcm_delivered_to_recipient, notification)
      perform
    end

    it 'marks the notification as delivered' do
      expect(delivery).to receive(:mark_delivered)
      perform
    end

    it 'logs that the notification was delivered' do
      expect(logger).to receive(:info).with("[MyApp] #{notification.id} sent to 1")
      perform
    end
  end

  describe 'all deliveries failed with Unavailable or InternalServerError 503' do
    before do
      allow(notification).to receive_messages(device_token: '1')
      allow(response).to receive_messages(code: 503, body: nil)
    end

    it 'reflects on any IDs which failed to receive the notification' do
      pending("Determine the correct cases where FCM should send fcm_failed_to_recipient")
      expect(delivery).to receive(:reflect).with(:fcm_failed_to_recipient, notification)
      perform
    end

    it 'retries the notification respecting the Retry-After header' do
      allow(response).to receive_messages(header: { 'retry-after' => 10 })
      expect(delivery).to receive(:mark_retryable).with(notification, now + 10.seconds)
      perform
    end

    it 'retries the notification using exponential back-off if the Retry-After header is not present' do
      expect(delivery).to receive(:mark_retryable).with(notification, now + 2)
      perform
    end

    it 'does not mark the notification as failed' do
      expect(delivery).not_to receive(:mark_failed)
      perform
    end

    it 'logs that the notification will be retried' do
      notification.retries = 1
      notification.deliver_after = now + 2
      expect(Rpush.logger).to receive(:warn).with("[MyApp] FCM responded with an Service Unavailable Error. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
      perform
    end
  end

  describe 'all deliveries failed with Unavailable or InternalServerError 500' do
    before do
      allow(notification).to receive_messages(device_token: '1')
      allow(response).to receive_messages(code: 500, body: nil)
    end

    it 'logs a warning that the notification has been re-queued.' do
      notification.retries = 3
      notification.deliver_after = now + 2**3
      expect(Rpush.logger).to receive(:warn).with("[MyApp] FCM responded with an Internal Error. Notification #{notification.id} will be retried after #{(now + 2**3).strftime('%Y-%m-%d %H:%M:%S')} (retry 3).")
      perform
    end

    it 'retries the notification in accordance with the exponential back-off strategy.' do
      notification.update_attribute(:retries, 2)
      expect(delivery).to receive(:mark_retryable).with(notification, now + 2**3)
      perform
    end
  end

  describe 'all deliveries failed with invalid token' do
    before do
      allow(notification).to receive_messages(device_token: '1')
      allow(response).to receive_messages(code: 404, body: { error: { status: 'NOT_FOUND', message: 'Requested entity was not found.' } }.to_json)
    end

    it 'reflects on invalid IDs' do
      expect(delivery).to receive(:reflect).with(:fcm_invalid_device_token, app, "NOT_FOUND: Requested entity was not found.", '1')
      perform_with_rescue
    end

    it 'marks a notification as failed if any ids are invalid' do
      expect(delivery).to receive(:mark_failed)
      expect(delivery).not_to receive(:mark_retryable)
      expect(store).not_to receive(:create_fcm_notification)
      perform_with_rescue
    end
  end
end
