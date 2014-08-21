require 'unit_spec_helper'

describe Rpush::Daemon::Adm::Delivery do
  let(:app) { Rpush::Adm::App.create!(name: 'MyApp', client_id: 'CLIENT_ID', client_secret: 'CLIENT_SECRET') }
  let(:notification) { Rpush::Adm::Notification.create!(app: app, registration_ids: ['xyz'], deliver_after: Time.now, data: { 'message' => 'test' }) }
  let(:logger) { double(error: nil, info: nil, warn: nil) }
  let(:response) { double(code: 200, header: {}) }
  let(:http) { double(shutdown: nil, request: response) }
  let(:now) { Time.parse('2012-10-14 00:00:00') }
  let(:batch) { double(mark_failed: nil, mark_delivered: nil, mark_retryable: nil, notification_processed: nil) }
  let(:delivery) { Rpush::Daemon::Adm::Delivery.new(app, http, notification, batch) }
  let(:store) { double(create_adm_notification: double(id: 2)) }

  def perform
    delivery.perform
  end

  before do
    app.access_token = 'ACCESS_TOKEN'
    app.access_token_expiration = Time.now + 1.month

    delivery.stub(reflect: nil)
    Rpush::Daemon.stub(store: store)
    Time.stub(now: now)
    Rpush.stub(logger: logger)
  end

  describe 'unknown error response' do
    before do
      response.stub(code: 408)
    end

    it 'marks the notification as failed because no successful delivery was made' do
      response.stub(body: JSON.dump('reason' => 'InvalidData'))
      error = Rpush::DeliveryError.new(408, notification.id, 'Request Timeout')
      delivery.should_receive(:mark_failed).with(error)
      expect { perform }.to raise_error(Rpush::DeliveryError)
    end
  end

  describe 'a 200 (Ok) response' do
    before do
      response.stub(code: 200)
    end

    it 'marks the notification as delivered if delivered successfully to all devices' do
      response.stub(body: JSON.dump('registrationID' => 'xyz'))
      delivery.should_receive(:mark_delivered)
      perform
    end

    it 'logs that the notification was delivered' do
      response.stub(body: JSON.dump('registrationID' => 'xyz'))
      logger.should_receive(:info).with("[MyApp] #{notification.id} sent to xyz")
      perform
    end

    it 'reflects on canonical IDs' do
      response.stub(body: JSON.dump('registrationID' => 'canonical123'))
      notification.stub(registration_ids: ['1'])
      delivery.should_receive(:reflect).with(:adm_canonical_id, '1', 'canonical123')
      perform
    end
  end

  describe 'a 400 (Bad Request) response' do
    before do
      response.stub(code: 400)
    end

    it 'marks the notification as failed because no successful delivery was made' do
      response.stub(body: JSON.dump('reason' => 'InvalidData'))
      error = Rpush::DeliveryError.new(nil, notification.id, 'Failed to deliver to all recipients.')
      delivery.should_receive(:mark_failed).with(error)
      expect { perform }.to raise_error(error)
    end

    it 'logs that the notification was not delivered' do
      response.stub(body: JSON.dump('reason' => 'InvalidRegistrationId'))
      logger.should_receive(:warn).with("[MyApp] bad_request: xyz (InvalidRegistrationId)")
      expect { perform }.to raise_error
    end

    it 'reflects' do
      response.stub(body: JSON.dump('registrationID' => 'canonical123', 'reason' => 'Unregistered'))
      notification.stub(registration_ids: ['1'])
      delivery.should_receive(:reflect).with(:adm_failed_to_recipient, notification, '1', 'Unregistered')
      expect { perform }.to raise_error
    end

  end

  describe 'a 401 (Unauthorized) response' do
    let(:http) { double(shutdown: nil) }
    let(:token_response) { double(code: 200, header: {}, body: JSON.dump('access_token' => 'ACCESS_TOKEN', 'expires_in' => 60)) }

    before do
      response.stub(code: 401, header: { 'retry-after' => 10 })

      # first request to deliver message that returns unauthorized response
      adm_uri = URI.parse(format(Rpush::Daemon::Adm::Delivery::AMAZON_ADM_URL, notification.registration_ids.first))
      http.should_receive(:request).with(adm_uri, instance_of(Net::HTTP::Post)).and_return(response)
    end

    it 'should retrieve a new access token and mark the notification for retry' do
      # request for access token
      http.should_receive(:request).with(Rpush::Daemon::Adm::Delivery::AMAZON_TOKEN_URI, instance_of(Net::HTTP::Post)).and_return(token_response)

      store.should_receive(:update_app).with(notification.app)
      delivery.should_receive(:mark_retryable).with(notification, now)

      perform
    end

    it 'should update the app with the new access token' do
      # request for access token
      http.should_receive(:request).with(Rpush::Daemon::Adm::Delivery::AMAZON_TOKEN_URI, instance_of(Net::HTTP::Post)).and_return(token_response)

      store.should_receive(:update_app).with do |app|
        app.access_token.should eq 'ACCESS_TOKEN'
        app.access_token_expiration.should eq now + 60.seconds
      end
      delivery.should_receive(:mark_retryable).with(notification, now)

      perform
    end

    it 'should log the error and stop retrying if new access token can\'t be retrieved' do
      token_response.stub(code: 404, body: "test")
      # request for access token
      http.should_receive(:request).with(Rpush::Daemon::Adm::Delivery::AMAZON_TOKEN_URI, instance_of(Net::HTTP::Post)).and_return(token_response)

      store.should_not_receive(:update_app).with(notification.app)
      delivery.should_not_receive(:mark_retryable)

      logger.should_receive(:warn).with("[MyApp] Could not retrieve access token from ADM: test")

      perform
    end
  end

  describe 'a 429 (Too Many Request) response' do
    let(:http) { double(shutdown: nil) }
    let(:notification) { Rpush::Adm::Notification.create!(app: app, registration_ids: %w(abc xyz), deliver_after: Time.now, collapse_key: 'sync', data: { 'message' => 'test' }) }
    let(:rate_limited_response) { double(code: 429, header: { 'retry-after' => 3600 }) }

    it 'should retry the entire notification respecting the Retry-After header if none sent out yet' do
      response.stub(code: 429, header: { 'retry-after' => 3600 })

      # first request to deliver message that returns too many request response
      adm_uri = URI.parse(format(Rpush::Daemon::Adm::Delivery::AMAZON_ADM_URL, notification.registration_ids.first))
      http.should_receive(:request).with(adm_uri, instance_of(Net::HTTP::Post)).and_return(response)

      delivery.should_receive(:mark_retryable).with(notification, now + 1.hour)
      perform
    end

    it 'should retry the entire notification using exponential backoff' do
      response.stub(code: 429, header: {})

      # first request to deliver message that returns too many request response
      adm_uri = URI.parse(format(Rpush::Daemon::Adm::Delivery::AMAZON_ADM_URL, notification.registration_ids.first))
      http.should_receive(:request).with(adm_uri, instance_of(Net::HTTP::Post)).and_return(response)

      delivery.should_receive(:mark_retryable).with(notification, Time.now + 2**(notification.retries + 1))
      perform
    end

    it 'should keep sent reg ids in original notification and create new notification with remaining reg ids for retry' do
      response.stub(code: 200, body: JSON.dump('registrationID' => 'abc'))

      # first request to deliver message succeeds
      adm_uri = URI.parse(format(Rpush::Daemon::Adm::Delivery::AMAZON_ADM_URL, 'abc'))
      http.should_receive(:request).with(adm_uri, instance_of(Net::HTTP::Post)).and_return(response)

      # first request to deliver message that returns too many request response
      adm_uri = URI.parse(format(Rpush::Daemon::Adm::Delivery::AMAZON_ADM_URL, 'xyz'))
      http.should_receive(:request).with(adm_uri, instance_of(Net::HTTP::Post)).and_return(rate_limited_response)

      store.should_receive(:update_notification).with do |notif|
        notif.registration_ids.include?('abc').should be_true
        notif.registration_ids.include?('xyz').should be_false
      end

      store.should_receive(:create_adm_notification).with do |attrs, _notification_data, reg_ids, deliver_after, notification_app|
        attrs.key?('collapse_key').should be_true
        attrs.key?('delay_while_idle').should be_true
        attrs.key?('app_id').should be_true

        reg_ids.should eq ['xyz']
        deliver_after.should eq now + 1.hour
        notification_app.should eq notification.app
      end

      delivery.should_receive(:mark_delivered)

      perform
    end
  end

  describe 'a 500 (Internal Server Error) response' do
    before do
      response.stub(code: 500)
    end

    it 'marks the notification as failed because no successful delivery was made' do
      error = Rpush::DeliveryError.new(nil, notification.id, 'Failed to deliver to all recipients.')
      delivery.should_receive(:mark_failed).with(error)
      expect { perform }.to raise_error(Rpush::DeliveryError)
    end

    it 'logs that the notification was not delivered' do
      logger.should_receive(:warn).with("[MyApp] internal_server_error: xyz (Internal Server Error)")
      expect { perform }.to raise_error(Rpush::DeliveryError)
    end
  end

  describe 'a 503 (Service Unavailable) response' do
    before do
      response.stub(code: 503, header: { 'retry-after' => 10 })
    end

    it 'should retry the notification respecting the Retry-After header' do
      delivery.should_receive(:mark_retryable).with(notification, now + 10.seconds)
      perform
    end
  end

  describe 'some registration ids succeeding and some failing' do
    let(:http) { double(shutdown: nil) }
    let(:notification) { Rpush::Adm::Notification.create!(app: app, registration_ids: %w(abc xyz), deliver_after: Time.now, collapse_key: 'sync', data: { 'message' => 'test' }) }
    let(:bad_request_response) { double(code: 400, body: JSON.dump('reason' => 'InvalidData')) }

    it 'should keep sent reg ids in original notification and create new notification with remaining reg ids for retry' do
      response.stub(code: 200, body: JSON.dump('registrationID' => 'abc'))

      # first request to deliver message succeeds
      adm_uri = URI.parse(format(Rpush::Daemon::Adm::Delivery::AMAZON_ADM_URL, 'abc'))
      http.should_receive(:request).with(adm_uri, instance_of(Net::HTTP::Post)).and_return(response)

      # first request to deliver message that returns too many request response
      adm_uri = URI.parse(format(Rpush::Daemon::Adm::Delivery::AMAZON_ADM_URL, 'xyz'))
      http.should_receive(:request).with(adm_uri, instance_of(Net::HTTP::Post)).and_return(bad_request_response)

      store.should_receive(:update_notification).with do |notif|
        notif.error_description.should eq "Failed to deliver to recipients: \nxyz: InvalidData"
      end

      delivery.should_receive(:mark_delivered)

      perform
    end
  end
end
