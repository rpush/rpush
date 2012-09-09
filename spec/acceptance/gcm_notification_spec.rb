require 'acceptance_spec_helper'

describe "GCM notification delivery" do
  let(:registration_id) { read_fixture('registration_id.txt').strip }
  let(:auth_key) { read_fixture('auth_key.txt').strip }

  before do
    setup_rapns
    @rapns = start_rapns
  end

  after do
    Process.kill('KILL', @rapns.pid) if @rapns
  end

  it 'delivers an notification with an valid registration id' do
    p registration_id
    p auth_key

    runner(<<-RUBY)
      app = Rapns::Gcm::App.create!(:name => "test", :auth_key => #{auth_key.inspect})
      Rapns::Gcm::Notification.create!(:registration_ids => [#{registration_id.inspect}], :data => {"test" => 1}, :app => app)
    RUBY

    delivered = false
    while true
      break if runner("puts Rapns::Gcm::Notification.first.failed") == 'true'
      delivered = runner("puts Rapns::Gcm::Notification.first.delivered") == 'true'
      break if delivered
    end
    delivered.should be_true
  end

  # it 'does not deliver an notification with an invalid device token' do
  #   runner(<<-RUBY)
  #     app = Rapns::Apns::App.create!(:name => "test", :environment => #{env.inspect}, :certificate => #{cert.inspect})
  #     Rapns::Apns::Notification.create!(:device_token => "a" * 64, :alert => "test", :app => app)
  #   RUBY

  #   failed = false
  #   while true
  #     break if runner("puts Rapns::Apns::Notification.first.delivered") == 'true'
  #     failed = runner("puts Rapns::Apns::Notification.first.failed") == 'true'
  #     break if failed
  #   end
  #   failed.should be_true
  # end
end
