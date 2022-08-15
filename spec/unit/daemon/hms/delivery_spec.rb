require 'unit_spec_helper'

describe Rpush::Daemon::Hms::Delivery do
  let(:app) { Fixtures.create!(:hms_app, name: 'MyApp', auth_key: 'abc123', hms_app_id: 'hms-app-id') }
  let(:notification) do
    notif = Rpush::Hms::Notification.new(
      app: app, registration_ids: ['xyz'], deliver_after: Time.now, title: 'title', body: 'body',
      notification: { click_action: { type: Rpush::Hms::Notification::CLICK_RICH_MEDIA } }.deep_stringify_keys,
      app_id: app.id
    )
    notif.set_uri(app.hms_app_id)
    notif.save! && notif
  end
  let(:logger) { double(error: nil, info: nil, warn: nil) }
  let(:response_body) { { code: '80000000', requestId: 'request-id', msg: 'msg' } }
  let(:response) { double(code: 200, header: {}, body: response_body.to_json) }
  let(:http) { double(shutdown: nil, request: response) }
  let(:now) { Time.parse('2012-10-14 00:00:00') }
  let(:batch) { double(mark_failed: nil, mark_delivered: nil, mark_retryable: nil, notification_processed: nil) }
  let(:token_provider) { double(token: 'auth-token') }
  let(:delivery) { Rpush::Daemon::Hms::Delivery.new(app, http, notification, batch, token_provider: token_provider) }
  let(:store) { double(create_gcm_notification: double(id: 2)) }

  def perform
    delivery.perform
  end

  def perform_with_rescue
    expect { perform }.to raise_error(StandardError)
  end

  before do
    allow(delivery).to receive_messages(reflect: nil, auth_token: 'bearer-token')
    allow(Rpush::Daemon).to receive_messages(store: store)
    allow(Time).to receive_messages(now: now)
    allow(Rpush).to receive_messages(logger: logger)
  end

  describe 'a 200 response' do
    before do
      allow(response).to receive_messages(code: 200)
    end

    it 'should mark notification as delivered' do
      expect(http).to receive(:request).and_return(response)
      perform
    end
  end

  describe 'a 503 response' do
    before { allow(response).to receive_messages(code: 503) }

    it 'logs a warning that the notification will be retried.' do
      notification.retries = 1
      notification.deliver_after = now + 2
      expect(logger).to receive(:warn).with("[MyApp] HMS responded with a Service Unavailable Error. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
      perform
    end

    it 'respects an integer Retry-After header' do
      allow(response).to receive_messages(header: { 'retry-after' => 10 })
      expect(delivery).to receive(:mark_retryable).with(notification, now + 10.seconds)
      perform
    end

    it 'respects a HTTP-date Retry-After header' do
      allow(response).to receive_messages(header: { 'retry-after' => 'Wed, 03 Oct 2012 20:55:11 GMT' })
      expect(delivery).to receive(:mark_retryable).with(notification, Time.parse('Wed, 03 Oct 2012 20:55:11 GMT'))
      perform
    end

    it 'defaults to exponential back-off if the Retry-After header is not present' do
      expect(delivery).to receive(:mark_retryable).with(notification, now + 2**1)
      perform
    end
  end

  describe 'a 502 response' do
    before { allow(response).to receive_messages(code: 502) }

    it 'logs a warning that the notification will be retried.' do
      notification.retries = 1
      notification.deliver_after = now + 2
      expect(logger).to receive(:warn).with("[MyApp] HMS responded with a Bad Gateway Error. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
      perform
    end

    it 'respects an integer Retry-After header' do
      allow(response).to receive_messages(header: { 'retry-after' => 10 })
      expect(delivery).to receive(:mark_retryable).with(notification, now + 10.seconds)
      perform
    end

    it 'respects a HTTP-date Retry-After header' do
      allow(response).to receive_messages(header: { 'retry-after' => 'Wed, 03 Oct 2012 20:55:11 GMT' })
      expect(delivery).to receive(:mark_retryable).with(notification, Time.parse('Wed, 03 Oct 2012 20:55:11 GMT'))
      perform
    end

    it 'defaults to exponential back-off if the Retry-After header is not present' do
      expect(delivery).to receive(:mark_retryable).with(notification, now + 2**1)
      perform
    end
  end

  describe 'a 500 response' do
    before do
      notification.update_attribute(:retries, 2)
      allow(response).to receive_messages(code: 500)
    end

    it 'logs a warning that the notification has been re-queued.' do
      notification.retries = 3
      notification.deliver_after = now + 2**3
      expect(Rpush.logger).to receive(:warn).with("[MyApp] HMS responded with an Internal Error. Notification #{notification.id} will be retried after #{(now + 2**3).strftime('%Y-%m-%d %H:%M:%S')} (retry 3).")
      perform
    end

    it 'retries the notification in accordance with the exponential back-off strategy.' do
      expect(delivery).to receive(:mark_retryable).with(notification, now + 2**3)
      perform
    end
  end

  describe 'an un-handled response' do
    before { allow(response).to receive_messages(code: 418) }

    it 'marks the notification as failed' do
      error = Rpush::DeliveryError.new(418, notification.id, '80000000: msg. RequestId: request-id')
      expect(delivery).to receive(:mark_failed).with(error)
      perform_with_rescue
    end
  end
end
