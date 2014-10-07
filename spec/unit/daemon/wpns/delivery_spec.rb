require 'unit_spec_helper'

describe Rpush::Daemon::Wpns::Delivery do
  let(:app) { Rpush::Wpns::App.create!(name: "MyApp") }
  let(:notification) { Rpush::Wpns::Notification.create!(app: app, data: { title: "MyApp", body: "Example notification", param: "/param1" }, uri: "http://some.example/", deliver_after: Time.now) }
  let(:logger) { double(error: nil, info: nil, warn: nil) }
  let(:response) { double(code: 200, header: {}) }
  let(:http) { double(shutdown: nil, request: response) }
  let(:now) { Time.parse('2012-10-14 00:00:00') }
  let(:batch) { double(mark_failed: nil, mark_delivered: nil, mark_retryable: nil, notification_processed: nil) }
  let(:delivery) { Rpush::Daemon::Wpns::Delivery.new(app, http, notification, batch) }
  let(:store) { double(create_wpns_notification: double(id: 2)) }

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

  shared_examples_for "an notification with some delivery faliures" do
    let(:new_notification) { Rpush::Wpns::Notification.where('id != ?', notification.id).first }

    before { response.stub(body: JSON.dump(body)) }

    it "marks the original notification falied" do
      delivery.should_receive(:mark_failed) do |error|
        error.message.should =~ error_description
      end
      perform_with_rescue
    end

    it "raises a DeliveryError" do
      expect { perform }.to raise_error(Rpush::DeliveryError)
    end
  end

  describe "an 200 response" do
    before do
      response.stub(code: 200)
    end

    it "marks the notification as delivered if delivered successfully to all devices" do
      response.stub(body: JSON.dump("failure" => 0))
      response.stub(to_hash: { "x-notificationstatus" => ["Received"] })
      batch.should_receive(:mark_delivered).with(notification)
      perform
    end

    it "retries the notification when the queue is full" do
      response.stub(body: JSON.dump("failure" => 0))
      response.stub(to_hash: { "x-notificationstatus" => ["QueueFull"] })
      batch.should_receive(:mark_retryable).with(notification, Time.now + (60 * 10))
      perform
    end

    it "marks the notification as failed if the notification is suppressed" do
      response.stub(body: JSON.dump("faliure" => 0))
      response.stub(to_hash: { "x-notificationstatus" => ["Suppressed"] })
      error = Rpush::DeliveryError.new(200, notification.id, 'Notification was received but suppressed by the service.')
      delivery.should_receive(:mark_failed).with(error)
      perform_with_rescue
    end
  end

  describe "an 400 response" do
    before { response.stub(code: 400) }
    it "marks notifications as failed" do
      error = Rpush::DeliveryError.new(400, notification.id, 'Bad XML or malformed notification URI.')
      delivery.should_receive(:mark_failed).with(error)
      perform_with_rescue
    end
  end

  describe "an 401 response" do
    before { response.stub(code: 401) }
    it "marks notifications as failed" do
      error = Rpush::DeliveryError.new(401, notification.id, 'Unauthorized to send a notification to this app.')
      delivery.should_receive(:mark_failed).with(error)
      perform_with_rescue
    end
  end

  describe "an 404 response" do
    before { response.stub(code: 404) }
    it "marks notifications as failed" do
      error = Rpush::DeliveryError.new(404, notification.id, 'Not Found')
      delivery.should_receive(:mark_failed).with(error)
      perform_with_rescue
    end
  end

  describe "an 405 response" do
    before { response.stub(code: 405) }
    it "marks notifications as failed" do
      error = Rpush::DeliveryError.new(405, notification.id, 'Method Not Allowed')
      delivery.should_receive(:mark_failed).with(error)
      perform_with_rescue
    end
  end

  describe "an 406 response" do
    before { response.stub(code: 406) }

    it "retries the notification" do
      batch.should_receive(:mark_retryable).with(notification, Time.now + (60 * 60))
      perform
    end

    it "logs a warning that the notification will be retried" do
      notification.retries = 1
      notification.deliver_after = now + 2
      logger.should_receive(:warn).with("[MyApp] Per-day throttling limit reached. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
      perform
    end
  end

  describe "an 412 response" do
    before { response.stub(code: 412) }

    it "retries the notification" do
      batch.should_receive(:mark_retryable).with(notification, Time.now + (60 * 60))
      perform
    end

    it "logs a warning that the notification will be retried" do
      notification.retries = 1
      notification.deliver_after = now + 2
      logger.should_receive(:warn).with("[MyApp] Device unreachable. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
      perform
    end
  end

  describe "an 503 response" do
    before { response.stub(code: 503) }

    it "retries the notification exponentially" do
      delivery.should_receive(:mark_retryable_exponential).with(notification)
      perform
    end

    it 'logs a warning that the notification will be retried.' do
      notification.retries = 1
      notification.deliver_after = now + 2
      logger.should_receive(:warn).with("[MyApp] Service Unavailable. Notification #{notification.id} will be retried after 2012-10-14 00:00:02 (retry 1).")
      perform
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
