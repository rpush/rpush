require 'acceptance_spec_helper'

describe "notification delivery" do
  let(:device_token) { read_fixture('device_token.txt').strip }
  let(:env) { 'production' }
  let(:cert) { read_fixture("#{env}.pem") }

  before do
    setup_rapns
    @console = Console.new
    @console.exec("Rapns::Apns::App.create!(:key => 'test', :environment => #{env.inspect}, :certificate => #{cert.inspect})")
    @rapns = start_rapns
  end

  after do
    @console.close if @console
    @rapns.close if @rapns
  end

  # it "successfully delivers a notification" do
  #   @console.exec("Rapns::Apns::Notification.create!(:device_token => #{device_token.inspect}, :alert => 'test', :app => 'test')")

  #   delivered = false
  #   while delivered != true
  #     output = @console.exec("Rapns::Apns::Notification.first.failed")
  #     output.should == 'false'
  #     output = @console.exec("Rapns::Apns::Notification.first.delivered")
  #     delivered = output == 'true'
  #     sleep 0.1
  #   end
  # end
end