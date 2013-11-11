require 'unit_spec_helper'

describe Rapns::Daemon::Gcm::Delivery do
  let(:app) { Rapns::Gcm::App.new(:name => 'MyApp', :auth_key => 'abc123') }
  let(:notification) { Rapns::Gcm::Notification.create!(:app => app, :registration_ids => ['xyz'], :deliver_after => Time.now) }
  let(:logger) { double(:error => nil, :info => nil, :warn => nil) }
  let(:response) { double(:code => 200, :header => {}) }
  let(:http) { double(:shutdown => nil, :request => response)}
  let(:now) { Time.parse('2012-10-14 00:00:00') }
  let(:batch) { double(:mark_failed => nil, :mark_delivered => nil, :mark_retryable => nil) }
  let(:delivery) { Rapns::Daemon::Gcm::Delivery.new(app, http, notification, batch) }
  let(:store) { double(:create_gcm_notification => double(:id => 2)) }

  def perform
    delivery.perform
  end

  before do
    delivery.stub(:reflect => nil)
    Rapns::Daemon.stub(:store => store)
    Time.stub(:now => now)
    Rapns.stub(:logger => logger)
  end

  shared_examples_for 'an notification with some delivery failures' do
    let(:new_notification) { Rapns::Gcm::Notification.where('id != ?', notification.id).first }

    before { response.stub(:body => JSON.dump(body)) }

    it 'marks the original notification as failed' do
      batch.should_receive(:mark_failed).with(notification, nil, error_description)
      perform rescue Rapns::DeliveryError
    end

    it 'creates a new notification for the unavailable devices' do
      notification.update_attributes(:registration_ids => ['id_0', 'id_1', 'id_2'], :data => {'one' => 1}, :collapse_key => 'thing', :delay_while_idle => true)
      response.stub(:header => { 'retry-after' => 10 })
      attrs = { 'collapse_key' => 'thing', 'delay_while_idle' => true, 'app_id' => app.id }
      store.should_receive(:create_gcm_notification).with(attrs, notification.data,
          ['id_0', 'id_2'], now + 10.seconds, notification.app)
      perform rescue Rapns::DeliveryError
    end

    it 'raises a DeliveryError' do
      expect { perform }.to raise_error(Rapns::DeliveryError)
    end
  end

  describe 'an 200 response' do
    before do
      response.stub(:code => 200)
    end

    it 'marks the notification as delivered if delivered successfully to all devices' do
      response.stub(:body => JSON.dump({ 'failure' => 0 }))
      batch.should_receive(:mark_delivered).with(notification)
      perform
    end

    it 'logs that the notification was delivered' do
      response.stub(:body => JSON.dump({ 'failure' => 0 }))
      logger.should_receive(:info).with("[MyApp] #{notification.id} sent to xyz")
      perform
    end

    it 'marks a notification as failed if any deliveries failed that cannot be retried.' do
      body = {
        'failure' => 1,
        'success' => 1,
        'results' => [
          { 'message_id' => '1:000' },
          { 'error' => 'InvalidDataKey' }
      ]}
      response.stub(:body => JSON.dump(body))
      batch.should_receive(:mark_failed).with(notification, nil, "Failed to deliver to all recipients. Errors: InvalidDataKey.")
      perform rescue Rapns::DeliveryError
    end

    it 'reflects on canonical IDs' do
      body = {
        'failure' => 0,
        'success' => 3,
        'canonical_ids' => 1,
        'results' => [
          { 'message_id' => '1:000' },
          { 'message_id' => '1:000', 'registration_id' => 'canonical123' },
          { 'message_id' => '1:000' },
        ]}

      response.stub(:body => JSON.dump(body))
      notification.stub(:registration_ids => ['1', '2', '3'])
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
              { 'message_id' => '1:000' },
          ]}

      response.stub(:body => JSON.dump(body))
      notification.stub(:registration_ids => ['1', '2', '3'])
      delivery.should_receive(:reflect).with(:gcm_invalid_registration_id, app, 'NotRegistered', '2')
      perform
    end

    it 'does not retry, raise or marks a notification as failed for invalid ids.' do
      body = {
          'failure' => 1,
          'success' => 2,
          'canonical_ids' => 0,
          'results' => [
              { 'message_id' => '1:000' },
              { 'error' => 'NotRegistered' },
              { 'message_id' => '1:000' },
          ]}

      response.stub(:body => JSON.dump(body))
      batch.should_not_receive(:mark_failed)
      batch.should_not_receive(:mark_retryable)
      store.should_not_receive(:create_gcm_notification)
      perform
    end

    describe 'all deliveries returned Unavailable or InternalServerError' do
      let(:body) {{
        'failure' => 2,
        'success' => 0,
        'results' => [
          { 'error' => 'Unavailable' },
          { 'error' => 'Unavailable' }
        ]}}

      before { response.stub(:body => JSON.dump(body)) }

      it 'retries the notification respecting the Retry-After header' do
        response.stub(:header => { 'retry-after' => 10 })
        batch.should_receive(:mark_retryable).with(notification, now + 10.seconds)
        perform
      end

      it 'retries the notification using exponential back-off if the Retry-After header is not present' do
        batch.should_receive(:mark_retryable).with(notification, now + 2)
        perform
      end

      it 'does not mark the notification as failed' do
        batch.should_not_receive(:mark_failed)
        perform
      end

      it 'logs that the notification will be retried' do
        notification.retries = 1
        notification.deliver_after = now + 2
        Rapns.logger.should_receive(:warn).with("All recipients unavailable. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
        perform
      end
    end

    shared_examples_for 'an notification with some delivery failures' do
      let(:new_notification) { Rapns::Gcm::Notification.where('id != ?', notification.id).first }

      before { response.stub(:body => JSON.dump(body)) }

      it 'marks the original notification as failed' do
        batch.should_receive(:mark_failed).with(notification, nil, error_description)
        perform rescue Rapns::DeliveryError
      end

      it 'creates a new notification for the unavailable devices' do
        notification.update_attributes(:registration_ids => ['id_0', 'id_1', 'id_2'], :data => {'one' => 1}, :collapse_key => 'thing', :delay_while_idle => true)
        response.stub(:header => { 'retry-after' => 10 })
        attrs = { 'collapse_key' => 'thing', 'delay_while_idle' => true, 'app_id' => app.id }
        store.should_receive(:create_gcm_notification).with(attrs, notification.data,
            ['id_0', 'id_2'], now + 10.seconds, notification.app)
        perform rescue Rapns::DeliveryError
      end

      it 'raises a DeliveryError' do
        expect { perform }.to raise_error(Rapns::DeliveryError)
      end
    end

    describe 'all deliveries failed with some as Unavailable or InternalServerError' do
      let(:body) {{
        'failure' => 3,
        'success' => 0,
        'results' => [
          { 'error' => 'Unavailable' },
          { 'error' => 'InvalidDataKey' },
          { 'error' => 'Unavailable' }
        ]}}
      let(:error_description) { /#{Regexp.escape("Failed to deliver to recipients 0, 1, 2. Errors: Unavailable, InvalidDataKey, Unavailable. 0, 2 will be retried as notification")} [\d]+\./ }
      it_should_behave_like 'an notification with some delivery failures'
    end
  end

  describe 'some deliveries failed with Unavailable or InternalServerError' do
    let(:body) {{
        'failure' => 2,
        'success' => 1,
        'results' => [
          { 'error' => 'Unavailable' },
          { 'message_id' => '1:000' },
          { 'error' => 'InternalServerError' }
        ]}}
    let(:error_description) { /#{Regexp.escape("Failed to deliver to recipients 0, 2. Errors: Unavailable, InternalServerError. 0, 2 will be retried as notification")} [\d]+\./ }
    it_should_behave_like 'an notification with some delivery failures'
  end

  describe 'an 503 response' do
    before { response.stub(:code => 503) }

    it 'logs a warning that the notification will be retried.' do
      notification.retries = 1
      notification.deliver_after = now + 2
      logger.should_receive(:warn).with("GCM responded with an Service Unavailable Error. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
      perform
    end

    it 'respects an integer Retry-After header' do
      response.stub(:header => { 'retry-after' => 10 })
      batch.should_receive(:mark_retryable).with(notification, now + 10.seconds)
      perform
    end

    it 'respects a HTTP-date Retry-After header' do
      response.stub(:header => { 'retry-after' => 'Wed, 03 Oct 2012 20:55:11 GMT' })
      batch.should_receive(:mark_retryable).with(notification, Time.parse('Wed, 03 Oct 2012 20:55:11 GMT'))
      perform
    end

    it 'defaults to exponential back-off if the Retry-After header is not present' do
      batch.should_receive(:mark_retryable).with(notification, now + 2 ** 1)
      perform
    end
  end

  describe 'an 500 response' do
    before do
      notification.update_attribute(:retries, 2)
      response.stub(:code => 500)
    end

    it 'logs a warning that the notification has been re-queued.' do
      notification.retries = 3
      notification.deliver_after = now + 2 ** 3
      Rapns.logger.should_receive(:warn).with("GCM responded with an Internal Error. Notification #{notification.id} will be retried after #{(now + 2 ** 3).strftime("%Y-%m-%d %H:%M:%S")} (retry 3).")
      perform
    end

    it 'retries the notification in accordance with the exponential back-off strategy.' do
      batch.should_receive(:mark_retryable).with(notification, now + 2 ** 3)
      perform
    end
  end

  describe 'an 401 response' do
    before { response.stub(:code => 401) }

    it 'raises an error' do
      expect { perform }.to raise_error(Rapns::DeliveryError)
    end
  end

  describe 'an 400 response' do
    before { response.stub(:code => 400) }

    it 'marks the notification as failed' do
      batch.should_receive(:mark_failed).with(notification, 400, 'GCM failed to parse the JSON request. Possibly an rapns bug, please open an issue.')
      perform rescue Rapns::DeliveryError
    end
  end

  describe 'an un-handled response' do
    before { response.stub(:code => 418) }

    it 'marks the notification as failed' do
      batch.should_receive(:mark_failed).with(notification, 418, "I'm a Teapot")
      perform rescue Rapns::DeliveryError
    end
  end
end
