require 'unit_spec_helper'

describe Rpush::Daemon::Gcm::Delivery do
  let(:app) { Rpush::Gcm::App.create!(name: 'MyApp', auth_key: 'abc123') }
  let(:notification) { Rpush::Gcm::Notification.create!(app: app, registration_ids: ['xyz'], deliver_after: Time.now) }
  let(:logger) { double(error: nil, info: nil, warn: nil) }
  let(:response) { double(code: 200, header: {}) }
  let(:http) { double(shutdown: nil, request: response) }
  let(:now) { Time.parse('2012-10-14 00:00:00') }
  let(:batch) { double(mark_failed: nil, mark_delivered: nil, mark_retryable: nil, notification_processed: nil) }
  let(:delivery) { Rpush::Daemon::Gcm::Delivery.new(app, http, notification, batch) }
  let(:store) { double(create_gcm_notification: double(id: 2)) }

  def perform
    delivery.perform
  end

  def perform_with_rescue
    expect { perform }.to raise_error
  end

  before do
    delivery.stub(reflect: nil)
    Rpush::Daemon.stub(store: store)
    Time.stub(now: now)
    Rpush.stub(logger: logger)
  end

  shared_examples_for 'a notification with some delivery failures' do
    let(:new_notification) { Rpush::Gcm::Notification.where('id != ?', notification.id).first }

    before { response.stub(body: JSON.dump(body)) }

    it 'marks the original notification as failed' do
      # error = Rpush::DeliveryError.new(nil, notification.id, error_description)
      delivery.should_receive(:mark_failed) do |error|
        error.to_s.should =~ error_description
      end
      perform_with_rescue
    end

    it 'creates a new notification for the unavailable devices' do
      notification.update_attributes(registration_ids: %w(id_0 id_1 id_2), data: { 'one' => 1 }, collapse_key: 'thing', delay_while_idle: true)
      response.stub(header: { 'retry-after' => 10 })
      attrs = { 'collapse_key' => 'thing', 'delay_while_idle' => true, 'app_id' => app.id }
      store.should_receive(:create_gcm_notification).with(attrs, notification.data,
                                                          %w(id_0 id_2), now + 10.seconds, notification.app)
      perform_with_rescue
    end

    it 'raises a DeliveryError' do
      expect { perform }.to raise_error(Rpush::DeliveryError)
    end
  end

  describe 'a 200 response' do
    before do
      response.stub(code: 200)
    end

    it 'reflects on any IDs which successfully received the notification' do
      body = {
        'failure' => 1,
        'success' => 1,
        'results' => [
          { 'message_id' => '1:000' },
          { 'error' => 'Err' }
        ]
      }

      response.stub(body: JSON.dump(body))
      notification.stub(registration_ids: %w(1 2))
      delivery.should_receive(:reflect).with(:gcm_delivered_to_recipient, notification, '1')
      delivery.should_not_receive(:reflect).with(:gcm_delivered_to_recipient, notification, '2')
      perform_with_rescue
    end

    it 'reflects on any IDs which failed to receive the notification' do
      body = {
        'failure' => 1,
        'success' => 1,
        'results' => [
          { 'error' => 'Err' },
          { 'message_id' => '1:000' }
        ]
      }

      response.stub(body: JSON.dump(body))
      notification.stub(registration_ids: %w(1 2))
      delivery.should_receive(:reflect).with(:gcm_failed_to_recipient, notification, 'Err', '1')
      delivery.should_not_receive(:reflect).with(:gcm_failed_to_recipient, notification, anything, '2')
      perform_with_rescue
    end

    it 'reflects on canonical IDs' do
      body = {
        'failure' => 0,
        'success' => 3,
        'canonical_ids' => 1,
        'results' => [
          { 'message_id' => '1:000' },
          { 'message_id' => '1:000', 'registration_id' => 'canonical123' },
          { 'message_id' => '1:000' }
        ] }

      response.stub(body: JSON.dump(body))
      notification.stub(registration_ids: %w(1 2 3))
      delivery.should_receive(:reflect).with(:gcm_canonical_id, '2', 'canonical123')
      perform
    end

    it 'reflects on invalid IDs' do
      body = {
        'failure' => 1,
        'success' => 2,
        'canonical_ids' => 0,
        'results' => [
          { 'message_id' => '1:000' },
          { 'error' => 'NotRegistered' },
          { 'message_id' => '1:000' }
        ]
      }

      response.stub(body: JSON.dump(body))
      notification.stub(registration_ids: %w(1 2 3))
      delivery.should_receive(:reflect).with(:gcm_invalid_registration_id, app, 'NotRegistered', '2')
      perform_with_rescue
    end

    describe 'when delivered successfully to all devices' do
      let(:body) do
        {
          'failure' => 0,
          'success' => 1,
          'results' => [{ 'message_id' => '1:000' }]
        }
      end

      before { response.stub(body: JSON.dump(body)) }

      it 'marks the notification as delivered' do
        delivery.should_receive(:mark_delivered)
        perform
      end

      it 'logs that the notification was delivered' do
        logger.should_receive(:info).with("[MyApp] #{notification.id} sent to xyz")
        perform
      end
    end

    it 'marks a notification as failed if any ids are invalid' do
      body = {
        'failure' => 1,
        'success' => 2,
        'canonical_ids' => 0,
        'results' => [
          { 'message_id' => '1:000' },
          { 'error' => 'NotRegistered' },
          { 'message_id' => '1:000' }
        ]
      }

      response.stub(body: JSON.dump(body))
      delivery.should_receive(:mark_failed)
      delivery.should_not_receive(:mark_retryable)
      store.should_not_receive(:create_gcm_notification)
      perform_with_rescue
    end

    it 'marks a notification as failed if any deliveries failed that cannot be retried' do
      body = {
        'failure' => 1,
        'success' => 1,
        'results' => [
          { 'message_id' => '1:000' },
          { 'error' => 'InvalidDataKey' }
        ] }
      response.stub(body: JSON.dump(body))
      error = Rpush::DeliveryError.new(nil, notification.id, 'Failed to deliver to all recipients. Errors: InvalidDataKey.')
      delivery.should_receive(:mark_failed).with(error)
      perform_with_rescue
    end

    describe 'all deliveries failed with Unavailable or InternalServerError' do
      let(:body) do
        {
          'failure' => 2,
          'success' => 0,
          'results' => [
            { 'error' => 'Unavailable' },
            { 'error' => 'Unavailable' }
          ]
        }
      end

      before do
        response.stub(body: JSON.dump(body))
        notification.stub(registration_ids: %w(1 2))
      end

      it 'retries the notification respecting the Retry-After header' do
        response.stub(header: { 'retry-after' => 10 })
        delivery.should_receive(:mark_retryable).with(notification, now + 10.seconds)
        perform
      end

      it 'retries the notification using exponential back-off if the Retry-After header is not present' do
        delivery.should_receive(:mark_retryable).with(notification, now + 2)
        perform
      end

      it 'does not mark the notification as failed' do
        delivery.should_not_receive(:mark_failed)
        perform
      end

      it 'logs that the notification will be retried' do
        notification.retries = 1
        notification.deliver_after = now + 2
        Rpush.logger.should_receive(:warn).with("[MyApp] All recipients unavailable. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
        perform
      end
    end

    describe 'all deliveries failed with some as Unavailable or InternalServerError' do
      let(:body) do
        { 'failure' => 3,
          'success' => 0,
          'results' => [
            { 'error' => 'Unavailable' },
            { 'error' => 'InvalidDataKey' },
            { 'error' => 'Unavailable' }
          ]
        }
      end
      let(:error_description) { /#{Regexp.escape("Failed to deliver to recipients 0, 1, 2. Errors: Unavailable, InvalidDataKey, Unavailable. 0, 2 will be retried as notification")} [\d]+\./ }
      it_should_behave_like 'a notification with some delivery failures'
    end

    describe 'some deliveries failed with Unavailable or InternalServerError' do
      let(:body) do
        { 'failure' => 2,
          'success' => 1,
          'results' => [
            { 'error' => 'Unavailable' },
            { 'message_id' => '1:000' },
            { 'error' => 'InternalServerError' }
          ]
        }
      end
      let(:error_description) { /#{Regexp.escape("Failed to deliver to recipients 0, 2. Errors: Unavailable, InternalServerError. 0, 2 will be retried as notification")} [\d]+\./ }
      it_should_behave_like 'a notification with some delivery failures'
    end
  end

  describe 'a 503 response' do
    before { response.stub(code: 503) }

    it 'logs a warning that the notification will be retried.' do
      notification.retries = 1
      notification.deliver_after = now + 2
      logger.should_receive(:warn).with("[MyApp] GCM responded with an Service Unavailable Error. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
      perform
    end

    it 'respects an integer Retry-After header' do
      response.stub(header: { 'retry-after' => 10 })
      delivery.should_receive(:mark_retryable).with(notification, now + 10.seconds)
      perform
    end

    it 'respects a HTTP-date Retry-After header' do
      response.stub(header: { 'retry-after' => 'Wed, 03 Oct 2012 20:55:11 GMT' })
      delivery.should_receive(:mark_retryable).with(notification, Time.parse('Wed, 03 Oct 2012 20:55:11 GMT'))
      perform
    end

    it 'defaults to exponential back-off if the Retry-After header is not present' do
      delivery.should_receive(:mark_retryable).with(notification, now + 2**1)
      perform
    end
  end

  describe 'a 500 response' do
    before do
      notification.update_attribute(:retries, 2)
      response.stub(code: 500)
    end

    it 'logs a warning that the notification has been re-queued.' do
      notification.retries = 3
      notification.deliver_after = now + 2**3
      Rpush.logger.should_receive(:warn).with("[MyApp] GCM responded with an Internal Error. Notification #{notification.id} will be retried after #{(now + 2**3).strftime("%Y-%m-%d %H:%M:%S")} (retry 3).")
      perform
    end

    it 'retries the notification in accordance with the exponential back-off strategy.' do
      delivery.should_receive(:mark_retryable).with(notification, now + 2**3)
      perform
    end
  end

  describe 'a 401 response' do
    before { response.stub(code: 401) }

    it 'raises an error' do
      expect { perform }.to raise_error(Rpush::DeliveryError)
    end
  end

  describe 'a 400 response' do
    before { response.stub(code: 400) }

    it 'marks the notification as failed' do
      error = Rpush::DeliveryError.new(400, notification.id, 'GCM failed to parse the JSON request. Possibly an Rpush bug, please open an issue.')
      delivery.should_receive(:mark_failed).with(error)
      perform_with_rescue
    end
  end

  describe 'an un-handled response' do
    before { response.stub(code: 418) }

    it 'marks the notification as failed' do
      error = Rpush::DeliveryError.new(418, notification.id, "I'm a Teapot")
      delivery.should_receive(:mark_failed).with(error)
      perform_with_rescue
    end
  end
end
