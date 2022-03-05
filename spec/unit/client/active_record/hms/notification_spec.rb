require 'unit_spec_helper'
require 'unit/notification_shared.rb'

describe Rpush::Client::ActiveRecord::Hms::Notification do
  it_should_behave_like 'an Notification subclass'

  let(:app) { Fixtures.create!(:hms_app) }
  let(:notification_class) { Rpush::Client::ActiveRecord::Hms::Notification }
  let(:notification) { notification_class.new }

  it 'limits the number of registration ids to 1000' do
    notification.registration_ids = ['a'] * (1000 + 1)
    expect(notification.valid?).to be_falsey
    expect(notification.errors[:base]).to eq ["Number of registration_ids cannot be larger than 1000."]
  end

  it 'sets the priority to high when set to high' do
    notification.priority = 'high'
    expect(notification.as_json.dig('message', 'android', 'urgency')).to eq 'HIGH'
  end

  it 'sets the priority to normal when set to normal' do
    notification.priority = 'normal'
    expect(notification.as_json.dig('message', 'android', 'urgency')).to eq 'NORMAL'
  end

  it 'validates the priority is either "normal" or "high"' do
    notification.priority = 'invalid'
    expect(notification.errors[:priority]).to eq ['must be one of either "high" or "normal"']
  end

  it 'excludes the priority if it is not defined' do
    expect(notification.as_json).not_to have_key 'priority'
  end

  context 'click action' do
    subject { notification.valid? }

    it 'validates action type is a Hash on assignment' do
      notification.click_action = []
      expect(notification.errors[:notification]).to eq ['"click_action" must be a hash']
    end

    it 'validates type is presence in action type on assignment' do
      notification.click_action = { 'foo' => 'bar' }
      expect(notification.errors[:notification]).to include('Key "type" is required in "click_action"')
    end

    it 'validates type enum in in action type on assignment' do
      notification.click_action = { 'type' => 'foo' }
      expect(notification.errors[:notification]).to include('foo is not a valid click action type')
    end

    it 'set click action type correctly' do
      notification.click_action = { 'type' => described_class::CLICK_START_APP }
      expect(notification.errors).to_not include(:notification)
    end
  end

  context '#priority' do
    let(:notification) { Fixtures.build(:hms_notification, priority: 'high', app_id: app.id) }

    it 'should save and retrieve the value correctly' do
      notification.save!
      expect(described_class.all.last.priority).to eq 1
    end
  end

  context '#as_json' do
    before do
      notification.test_only = true
      notification.body = 'body'
      notification.title = 'title'
      notification.priority = 'high'
      notification.collapse_key = 1
      notification.registration_ids = ['token1']
      notification.click_action = {
        'type' => described_class::CLICK_START_APP,
      }
      notification.data = { message: 'message' }
    end

    subject { notification.as_json }

    it 'should serialize' do
      expect(subject).to eq({
                              "validate_only": true,
                              "message": {
                                "android": {
                                  "collapse_key": 1,
                                  "urgency": "HIGH",
                                  "notification": {
                                    "click_action": { "type" => 3 },
                                    "title": "title",
                                    "body": "body"
                                  }
                                },
                                "token": ['token1'],
                                "data": "{\"message\":\"message\"}"
                              }
                            }.deep_stringify_keys)
    end
  end
end if active_record?
