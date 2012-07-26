require "spec_helper"

describe Rapns::Notification do
  it { should validate_presence_of(:app) }
end