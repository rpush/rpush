# frozen_string_literal: true

shared_examples_for 'Rpush::Client::ActiveRecord::App' do
  it 'validates the uniqueness of name within type and environment' do
    Rpush::Apns::App.create!(name: 'test', environment: 'production', certificate: TEST_CERT)
    app = Rpush::Apns::App.new(name: 'test', environment: 'production', certificate: TEST_CERT)
    expect(app.valid?).to be(false)
    expect(app.errors[:name]).to eq ['has already been taken']

    app = Rpush::Apns::App.new(name: 'test', environment: 'development', certificate: TEST_CERT)
    expect(app.valid?).to be(true)

    app = Rpush::Fcm::App.new(name: 'test', environment: 'production', json_key: TEST_CERT)
    expect(app.valid?).to be(true)
  end
end
