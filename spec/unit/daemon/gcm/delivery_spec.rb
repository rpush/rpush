require 'unit_spec_helper'

describe Rapns::Daemon::Gcm::Delivery do
  let(:app) { Rapns::Gcm::App.new(:name => 'MyApp', :auth_key => 'abc123') }
  let(:notification) { Rapns::Gcm::Notification.create!(:app => app, :registration_ids => ['xyz']) }
  let(:logger) { stub(:error => nil, :info => nil, :warn => nil) }
  let(:response) { stub(:code => 200, :header => {}) }
  let(:http) { stub(:shutdown => nil, :request => response)}
  let(:now) { Time.parse('2012-10-14 00:00:00') }
  let(:delivery) { Rapns::Daemon::Gcm::Delivery.new(app, http, notification) }

  def perform
    delivery.perform
  end

  before do
    Time.stub(:now => now)
    Rapns::Daemon.stub(:logger => logger)
  end

  describe 'an 200 response' do
    before do
      response.stub(:code => 200)
    end

    it 'marks the notification as delivered if delivered successfully to all devices' do
      response.stub(:body => JSON.dump({ 'failure' => 0 }))
      expect do
        perform
      end.to change(notification, :delivered).to(true)
    end

    it 'reflects the notification was delivered' do
      response.stub(:body => JSON.dump({ 'failure' => 0 }))
      delivery.should_receive(:reflect).with(:notification_delivered, notification)
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
          { 'error' => 'NotRegistered' }
      ]}
      response.stub(:body => JSON.dump(body))
      perform rescue Rapns::DeliveryError
      notification.reload
      notification.failed.should be_true
      notification.error_code = nil
      notification.error_description = "Weee"
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
        perform
        notification.reload
        notification.retries.should == 1
        notification.deliver_after.should == now + 10.seconds
      end

      it 'retries the notification using exponential back-off if the Retry-After header is not present' do
        notification.update_attribute(:retries, 8)
        perform
        notification.reload
        notification.retries.should == 9
        notification.deliver_after.should == now + 2 ** 9
      end

      it 'does not mark the notification as failed' do
        expect do
          perform
          notification.reload
        end.to_not change(notification, :failed).to(true)
      end

      it 'logs that the notification will be retried' do
        Rapns::Daemon.logger.should_receive(:warn).with("All recipients unavailable. Notification #{notification.id} will be retired after 2012-10-14 00:00:02 (retry 1).")
        perform
      end
    end

    shared_examples_for 'an notification with some delivery failures' do
      let(:new_notification) { Rapns::Gcm::Notification.where('id != ?', notification.id).first }

      before { response.stub(:body => JSON.dump(body)) }

      it 'marks the original notification as failed' do
        perform rescue Rapns::DeliveryError
        notification.reload
        notification.failed.should be_true
        notification.failed_at = now
        notification.error_code.should be_nil
        notification.error_description.should == error_description
      end

      it 'reflects the notification delivery failed' do
        delivery.should_receive(:reflect).with(:notification_failed, notification)
        perform rescue Rapns::DeliveryError
      end

      it 'creates a new notification for the unavailable devices' do
        notification.update_attributes(:registration_ids => ['id_0', 'id_1', 'id_2'], :data => {'one' => 1}, :collapse_key => 'thing', :delay_while_idle => true)
        perform rescue Rapns::DeliveryError
        new_notification.registration_ids.should == ['id_0', 'id_2']
        new_notification.data.should == {'one' => 1}
        new_notification.collapse_key.should == 'thing'
        new_notification.delay_while_idle.should be_true
      end

      it 'sets the delivery time on the new notification to respect the Retry-After header' do
        response.stub(:header => { 'retry-after' => 10 })
        perform rescue Rapns::DeliveryError
        new_notification.deliver_after.should == now + 10.seconds
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
          { 'error' => 'NotRegistered' },
          { 'error' => 'Unavailable' }
        ]}}
      let(:error_description) { "Failed to deliver to recipients 0, 1, 2. Errors: Unavailable, NotRegistered, Unavailable. 0, 2 will be retried as notification #{notification.id + 1}." }
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
    let(:error_description) { "Failed to deliver to recipients 0, 2. Errors: Unavailable, InternalServerError. 0, 2 will be retried as notification #{notification.id + 1}." }
    it_should_behave_like 'an notification with some delivery failures'
  end

  describe 'an 503 response' do
    before { response.stub(:code => 503) }

    it 'logs a warning that the notification will be retried.' do
      logger.should_receive(:warn).with("GCM responded with an Service Unavailable Error. Notification #{notification.id} will be retired after 2012-10-14 00:00:02 (retry 1).")
      perform
    end

    it 'respects an integer Retry-After header' do
      response.stub(:header => { 'retry-after' => 10 })
      expect do
        perform
      end.to change(notification, :deliver_after).to(now + 10)
    end

    it 'respects a HTTP-date Retry-After header' do
      response.stub(:header => { 'retry-after' => 'Wed, 03 Oct 2012 20:55:11 GMT' })
      expect do
        perform
      end.to change(notification, :deliver_after).to(Time.parse('Wed, 03 Oct 2012 20:55:11 GMT'))
    end

    it 'defaults to exponential back-off if the Retry-After header is not present' do
      expect do
        perform
      end.to change(notification, :deliver_after).to(now + 2 ** 1)
    end

    it 'reflects the notification will be retried' do
      delivery.should_receive(:reflect).with(:notification_will_retry, notification)
      perform
    end
  end

  describe 'an 500 response' do
    before do
      notification.update_attribute(:retries, 2)
      response.stub(:code => 500)
    end

    it 'logs a warning that the notification has been re-queued.' do
      Rapns::Daemon.logger.should_receive(:warn).with("GCM responded with an Internal Error. Notification #{notification.id} will be retired after #{(now + 2 ** 3).strftime("%Y-%m-%d %H:%M:%S")} (retry 3).")
      perform
    end

    it 'sets deliver_after on the notification in accordance with the exponential back-off strategy.' do
      expect do
        perform
        notification.reload
      end.to change(notification, :deliver_after).to(now + 2 ** 3)
    end

    it 'reflects the notification will be retried' do
      delivery.should_receive(:reflect).with(:notification_will_retry, notification)
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
      perform rescue Rapns::DeliveryError
      notification.reload
      notification.failed.should be_true
      notification.failed_at.should == now
      notification.error_code.should == 400
      notification.error_description.should == 'GCM failed to parse the JSON request. Possibly an rapns bug, please open an issue.'
    end

    it 'reflects the notification delivery failed' do
      delivery.should_receive(:reflect).with(:notification_failed, notification)
      perform rescue Rapns::DeliveryError
    end
  end

  describe 'an un-handled response' do
    before { response.stub(:code => 418) }

    it 'marks the notification as failed' do
      perform rescue Rapns::DeliveryError
      notification.reload
      notification.failed.should be_true
      notification.failed_at.should == now
      notification.error_code.should == 418
      notification.error_description.should == "I'm a Teapot"
    end

    it 'reflects the notification delivery failed' do
      delivery.should_receive(:reflect).with(:notification_failed, notification)
      perform rescue Rapns::DeliveryError
    end
  end
end
