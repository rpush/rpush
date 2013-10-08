require 'unit_spec_helper'

describe Rapns::Daemon::Adm::Delivery do
  let(:app) { Rapns::Adm::App.new(:name => 'MyApp', :client_id => 'CLIENT_ID', :client_secret => 'CLIENT_SECRET') }
  let(:notification) { Rapns::Adm::Notification.create!(:app => app, :registration_ids => ['xyz'], :deliver_after => Time.now, :data => {'message' => 'test'}) }
  let(:logger) { double(:error => nil, :info => nil, :warn => nil) }
  let(:response) { double(:code => 200, :header => {}) }
  let(:http) { double(:shutdown => nil, :request => response)}
  let(:now) { Time.parse('2012-10-14 00:00:00') }
  let(:batch) { double(:mark_failed => nil, :mark_delivered => nil, :mark_retryable => nil) }
  let(:delivery) { Rapns::Daemon::Adm::Delivery.new(app, http, notification, batch) }
  let(:store) { double(:create_adm_notification => double(:id => 2)) }

  def perform
    delivery.perform
  end

  before do
    app.access_token = 'ACCESS_TOKEN'
    app.access_token_expiration = Time.now + 1.month

    delivery.stub(:reflect => nil)
    Rapns::Daemon.stub(:store => store)
    Time.stub(:now => now)
    Rapns.stub(:logger => logger)
  end

  describe 'a 200 (Ok) response' do
    before do
      response.stub(:code => 200)
    end

    it 'marks the notification as delivered if delivered successfully to all devices' do
      response.stub(:body => JSON.dump({ 'registrationID' => 'xyz' }))
      batch.should_receive(:mark_delivered).with(notification)
      perform
    end

    it 'logs that the notification was delivered' do
      response.stub(:body => JSON.dump({ 'registrationID' => 'xyz' }))
      logger.should_receive(:info).with("[MyApp] #{notification.id} sent to xyz")
      perform
    end

    it 'reflects on canonical IDs' do
      response.stub(:body => JSON.dump({'registrationID' => 'canonical123' }))
      notification.stub(:registration_ids => ['1'])
      delivery.should_receive(:reflect).with(:adm_canonical_id, '1', 'canonical123')
      perform
    end
  end

  describe 'a 400 (Bad Request) response' do
    before do
      response.stub(:code => 400)
    end

    it 'marks the notification as failed because no successful delivery was made' do
      response.stub(:body => JSON.dump({ 'reason' => 'InvalidData' }))
      batch.should_receive(:mark_failed).with(notification, nil, 'Failed to deliver to all recipients.')
      expect { perform }.to raise_error(Rapns::DeliveryError)
    end

    it 'logs that the notification was not delivered' do
      response.stub(:body => JSON.dump({ 'reason' => 'InvalidRegistrationId' }))
      logger.should_receive(:warn).with("[MyApp] bad_request: xyz (InvalidRegistrationId)")
      expect { perform }.to raise_error(Rapns::DeliveryError)
    end
  end

  describe 'a 401 (Unauthorized) response' do
    let(:http) { double(:shutdown => nil)}
    let(:token_response) { double(:code => 200, :header => {}, :body => JSON.dump({'access_token' => 'ACCESS_TOKEN', 'expires_in' => 60})) }

    before do
      response.stub(:code => 401, :header => { 'retry-after' => 10 })

      # first request to deliver message that returns unauthorized response
      adm_uri = URI.parse(Rapns::Daemon::Adm::Delivery::AMAZON_ADM_URL % { registration_id: notification.registration_ids.first })
      http.should_receive(:request).with(adm_uri, instance_of(Net::HTTP::Post)).and_return(response)

      # request for access token
      http.should_receive(:request).with(Rapns::Daemon::Adm::Delivery::AMAZON_TOKEN_URI, instance_of(Net::HTTP::Post)).and_return(token_response)
    end

    it 'should retrieve a new access token and mark the notification for retry' do
      store.should_receive(:update_app).with(notification.app)
      batch.should_receive(:mark_retryable).with(notification, now)

      perform
    end

    it 'should update the app with the new access token' do
      store.should_receive(:update_app).with do |app|
        app.access_token.should == 'ACCESS_TOKEN'
        app.access_token_expiration.should == now + 60.seconds
      end
      batch.should_receive(:mark_retryable).with(notification, now)

      perform
    end
  end

  describe 'a 429 (Too Many Request) response' do
    let(:http) { double(:shutdown => nil) }
    let(:notification) { Rapns::Adm::Notification.create!(:app => app, :registration_ids => ['abc','xyz'], :deliver_after => Time.now, :collapse_key => 'sync', :data => {'message' => 'test'}) }
    let(:too_many_request_response) { double(:code => 429, :header => { 'retry-after' => 3600 }) }

    it 'should retry the entire notification respecting the Retry-After header if none sent out yet' do
      response.stub(:code => 429, :header => { 'retry-after' => 3600 })

      # first request to deliver message that returns too many request response
      adm_uri = URI.parse(Rapns::Daemon::Adm::Delivery::AMAZON_ADM_URL % { registration_id: notification.registration_ids.first })
      http.should_receive(:request).with(adm_uri, instance_of(Net::HTTP::Post)).and_return(response)

      batch.should_receive(:mark_retryable).with(notification, now + 1.hour)
      perform
    end

    it 'should keep sent reg ids in original notification and create new notification with remaining reg ids for retry' do
      response.stub(:code => 200, :body => JSON.dump({ 'registrationID' => 'abc' }))

      # first request to deliver message succeeds
      adm_uri = URI.parse(Rapns::Daemon::Adm::Delivery::AMAZON_ADM_URL % { registration_id: 'abc' })
      http.should_receive(:request).with(adm_uri, instance_of(Net::HTTP::Post)).and_return(response)

      # first request to deliver message that returns too many request response
      adm_uri = URI.parse(Rapns::Daemon::Adm::Delivery::AMAZON_ADM_URL % { registration_id: 'xyz' })
      http.should_receive(:request).with(adm_uri, instance_of(Net::HTTP::Post)).and_return(too_many_request_response)

      store.should_receive(:update_notification).with do |notif|
        notif.registration_ids.include?('abc').should be_true
        notif.registration_ids.include?('xyz').should be_false
      end

      store.should_receive(:create_adm_notification).with do |attrs, notification_data, reg_ids, deliver_after, notification_app|
        attrs.has_key?('collapse_key').should be_true
        attrs.has_key?('delay_while_idle').should be_true
        attrs.has_key?('app_id').should be_true

        reg_ids.should == ['xyz']
        deliver_after.should == now + 1.hour
        notification_app.should == notification.app
      end

      batch.should_receive(:mark_delivered).with(notification)

      perform
    end
  end

  describe 'a 500 (Internal Server Error) response' do
    before do
      response.stub(:code => 500)
    end

    it 'marks the notification as failed because no successful delivery was made' do
      batch.should_receive(:mark_failed).with(notification, nil, 'Failed to deliver to all recipients.')
      expect { perform }.to raise_error(Rapns::DeliveryError)
    end

    it 'logs that the notification was not delivered' do
      logger.should_receive(:warn).with("[MyApp] internal_server_error: xyz (Internal Server Error)")
      expect { perform }.to raise_error(Rapns::DeliveryError)
    end
  end

  describe 'a 503 (Service Unavailable) response' do
    before do
      response.stub(:code => 503, :header => { 'retry-after' => 10 })
    end

    it 'should retry the notification respecting the Retry-After header' do
      batch.should_receive(:mark_retryable).with(notification, now + 10.seconds)
      perform
    end
  end

  describe 'some registration ids succeeding and some failing' do
    let(:http) { double(:shutdown => nil) }
    let(:notification) { Rapns::Adm::Notification.create!(:app => app, :registration_ids => ['abc','xyz'], :deliver_after => Time.now, :collapse_key => 'sync', :data => {'message' => 'test'}) }
    let(:bad_request_response) { double(:code => 400, :body => JSON.dump({ 'reason' => 'InvalidData' })) }

    it 'should keep sent reg ids in original notification and create new notification with remaining reg ids for retry' do
      response.stub(:code => 200, :body => JSON.dump({ 'registrationID' => 'abc' }))

      # first request to deliver message succeeds
      adm_uri = URI.parse(Rapns::Daemon::Adm::Delivery::AMAZON_ADM_URL % { registration_id: 'abc' })
      http.should_receive(:request).with(adm_uri, instance_of(Net::HTTP::Post)).and_return(response)

      # first request to deliver message that returns too many request response
      adm_uri = URI.parse(Rapns::Daemon::Adm::Delivery::AMAZON_ADM_URL % { registration_id: 'xyz' })
      http.should_receive(:request).with(adm_uri, instance_of(Net::HTTP::Post)).and_return(bad_request_response)

      store.should_receive(:update_notification).with do |notif|
        notif.error_description.should == "Failed to deliver to recipients: \nxyz: InvalidData"
      end

      batch.should_receive(:mark_delivered).with(notification)

      perform
    end
  end
end