require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::App do
  it 'validates the uniqueness of name within type and environment' do
    Rpush::Client::ActiveRecord::Apns::App.create!(name: 'test', environment: 'production', certificate: TEST_CERT)
    app = Rpush::Client::ActiveRecord::Apns::App.new(name: 'test', environment: 'production', certificate: TEST_CERT)
    expect(app.valid?).to eq(false)
    expect(app.errors[:name]).to eq ['has already been taken']

    app = Rpush::Client::ActiveRecord::Apns::App.new(name: 'test', environment: 'development', certificate: TEST_CERT)
    expect(app.valid?).to eq(true)

    app = Rpush::Client::ActiveRecord::Gcm::App.new(name: 'test', environment: 'production', auth_key: TEST_CERT)
    expect(app.valid?).to eq(true)
  end

  context 'validating certificates' do
    it 'rescues from certificate error' do
      app = Rpush::Client::ActiveRecord::Apns::App.new(name: 'test', environment: 'development', certificate: 'bad')
      expect { app.valid? }.not_to raise_error
      expect(app.valid?).to eq(false)
    end

    it 'raises other errors' do
      app = Rpush::Client::ActiveRecord::Apns::App.new(name: 'test', environment: 'development', certificate: 'bad')
      allow(OpenSSL::X509::Certificate).to receive(:new).and_raise(NameError, 'simulating no openssl')
      expect { app.valid? }.to raise_error(NameError)
    end
  end
end if active_record?
