# frozen_string_literal: true

require 'unit_spec_helper'

shared_examples 'Rpush::Client::Adm::App' do
  subject { described_class.new(name: 'test', environment: 'development', client_id: 'CLIENT_ID', client_secret: 'CLIENT_SECRET') }

  it 'is valid if properly instantiated' do
    expect(subject).to be_valid
  end

  it 'is invalid if name' do
    subject.name = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:name]).to eq ["can't be blank"]
  end

  it 'is invalid if missing client_id' do
    subject.client_id = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:client_id]).to eq ["can't be blank"]
  end

  it 'is invalid if missing client_secret' do
    subject.client_secret = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:client_secret]).to eq ["can't be blank"]
  end

  describe '#access_token_expired?' do
    before do
      Timecop.freeze(Time.zone.now)
    end

    after do
      Timecop.return
    end

    it 'returns true if access_token_expiration is nil' do
      expect(subject.access_token_expired?).to be(true)
    end

    it 'returns true if expired' do
      subject.access_token_expiration = 5.minutes.ago
      expect(subject.access_token_expired?).to be(true)
    end

    it 'returns false if not expired' do
      subject.access_token_expiration = 5.minutes.from_now
      expect(subject.access_token_expired?).to be(false)
    end
  end
end
