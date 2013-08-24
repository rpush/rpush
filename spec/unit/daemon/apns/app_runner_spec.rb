require 'unit_spec_helper'
require File.dirname(__FILE__) + '/../app_runner_shared.rb'

describe Rapns::Daemon::Apns::AppRunner do
  it_behaves_like 'an AppRunner subclass'

  let(:app_class) { Rapns::Apns::App }
  let(:app) { app_class.create!(:name => 'my_app', :environment => 'development',
                                :certificate => TEST_CERT, :password => 'pass') }
  let(:runner) { Rapns::Daemon::Apns::AppRunner.new(app) }
  let(:handler) { double(:start => nil, :stop => nil, :queue= => nil) }
  let(:receiver) { double(:start => nil, :stop => nil) }
  let(:config) { double(:feedback_poll => 60, :push => false) }
  let(:logger) { double(:info => nil, :warn => nil, :error => nil) }

  before do
    Rapns.stub(:logger => logger, :config => config)
    Rapns::Daemon::Apns::DeliveryHandler.stub(:new => handler)
    Rapns::Daemon::Apns::FeedbackReceiver.stub(:new => receiver)
  end

  it 'instantiates a new feedback receiver when started' do
    Rapns::Daemon::Apns::FeedbackReceiver.should_receive(:new).with(app, 60)
    runner.start
  end

  it 'starts the feedback receiver' do
    receiver.should_receive(:start)
    runner.start
  end

  it 'stops the feedback receiver' do
    runner.start
    receiver.should_receive(:stop)
    runner.stop
  end

  it 'does not check for feedback when in push mode' do
    config.stub(:push => true)
    Rapns::Daemon::Apns::FeedbackReceiver.should_not_receive(:new)
    runner.start
  end

  it 'reflects if the certificate will expire soon' do
    cert = OpenSSL::X509::Certificate.new(app.certificate)
    runner.should_receive(:reflect).with(:apns_certificate_will_expire, app, cert.not_after)
    Timecop.freeze(cert.not_after - 3.days) { runner.start }
  end

  it 'logs that the certificate will expire soon' do
    cert = OpenSSL::X509::Certificate.new(app.certificate)
    logger.should_receive(:warn).with("[#{app.name}] Certificate will expire at 2022-09-07 03:18:32 UTC.")
    Timecop.freeze(cert.not_after - 3.days) { runner.start }
  end

  it 'does not reflect if the certificate will not expire soon' do
    cert = OpenSSL::X509::Certificate.new(app.certificate)
    runner.should_not_receive(:reflect).with(:apns_certificate_will_expire, app, kind_of(Time))
    Timecop.freeze(cert.not_after - 2.months) { runner.start }
  end

  it 'logs that the certificate has expired' do
    cert = OpenSSL::X509::Certificate.new(app.certificate)
    logger.should_receive(:error).with("[#{app.name}] Certificate expired at 2022-09-07 03:18:32 UTC.")
    Timecop.freeze(cert.not_after + 1.day) { runner.start rescue Rapns::Apns::CertificateExpiredError }
  end

  it 'raises an error if the certificate has expired' do
    cert = OpenSSL::X509::Certificate.new(app.certificate)
    Timecop.freeze(cert.not_after + 1.day) do
      expect { runner.start }.to raise_error(Rapns::Apns::CertificateExpiredError)
    end
  end
end
