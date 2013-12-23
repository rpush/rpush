require 'unit_spec_helper'

describe Rapns::Daemon::Wpns::Delivery do
  let(:app) { Rapns::Wpns::App.new(:name => "MyApp") }
  let(:notification) { Rapns::Wpns::Notification.create!(:app => app, :uri => "http://some.example/", :deliver_after => Time.now) }
  let(:logger) { double(:error => nil, :info => nil, :warn => nil) }
  let(:response) { double(:code => 200, :header => {}) }
  let(:http) { double(:shutdown => nil, :request => response) }
  let(:now) { Time.parse('2012-10-14 00:00:00') }
  let(:batch) { double(:mark_failed => nil, :mark_delivered => nil) }
  let(:delivery) { Rapns::Daemon::Wpns::Delivery.new(app, http, notification, batch) }
  let(:store) { double(:create_wpns_notification => double(:id => 2)) }

  def perform
    delivery.perform
  end

  before do
    delivery.stub(:reflect => nil)
    Rapns::Daemon.stub(:store => store)
    Time.stub(:now => now)
    Rapns.stub(:logger => logger)
  end

  shared_examples_for "an notification with some delivery faliures" do
    let(:new_notification) { Rapns::Wpns::Notification.where('id != ?', notification.id).first }

    before { response.stub(:body => JSON.dump(body)) }

    it "marks the original notification falied" do
      batch.should_receive(:mark_failed).with(notification, nil, error_description)
      perform rescue Rapns::DeliveryError
    end

    it "raises a DeliveryError" do
      expect { perform }.to raise_error(Rapns::DeliveryError)
    end
  end

  describe "an 200 response" do
    before do
      response.stub(:code => 200)
    end

    it "marks the notification as delivered if delivered successfully to all devices" do
      response.stub(:body => JSON.dump({ "failure" => 0 }))
      batch.should_receive(:mark_delivered).with(notification)
      perform
    end
  end

  describe "an 400 response" do
    before { response.stub(:code => 400) }
    it "marks notifications as failed" do
      batch.should_receive(:mark_failed).with(notification, 400, "Waka")
      perform rescue Rapns::DeliveryError
    end
  end
end
