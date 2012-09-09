require 'acceptance_spec_helper'

describe "APNs notification delivery" do
  let(:device_token) { read_fixture('device_token.txt').strip }
  let(:env) { 'production' }
  let(:cert) { read_fixture("#{env}.pem") }

  before do
    setup_rapns
    @rapns = start_rapns
  end

  after do
    Process.kill('KILL', @rapns.pid) if @rapns
  end

  it 'delivers an notification with an valid device token' do
    runner(<<-RUBY)
      app = Rapns::Apns::App.create!(:name => "test", :environment => #{env.inspect}, :certificate => #{cert.inspect})
      Rapns::Apns::Notification.create!(:device_token => #{device_token.inspect}, :alert => "test", :app => app)
    RUBY

    delivered = false
    while true
      break if runner("puts Rapns::Apns::Notification.first.failed") == 'true'
      delivered = runner("puts Rapns::Apns::Notification.first.delivered") == 'true'
      break if delivered
    end
    delivered.should be_true
  end

  it 'does not deliver an notification with an invalid device token' do
    runner(<<-RUBY)
      app = Rapns::Apns::App.create!(:name => "test", :environment => #{env.inspect}, :certificate => #{cert.inspect})
      Rapns::Apns::Notification.create!(:device_token => "a" * 64, :alert => "test", :app => app)
    RUBY

    failed = false
    while true
      break if runner("puts Rapns::Apns::Notification.first.delivered") == 'true'
      failed = runner("puts Rapns::Apns::Notification.first.failed") == 'true'
      break if failed
    end
    failed.should be_true
  end
end