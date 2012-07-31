require "unit_spec_helper"

describe Rapns::Notification do
  it { should validate_numericality_of(:expiry) }

  it 'validates at least one app is assigned' do
    n = Rapns::Notification.new
    n.valid?
    n.errors[:app].should == ['at least one app required.']

    n = Rapns::Notification.new
    n.app = []
    n.valid?
    n.errors[:app].should == ['at least one app required.']

    n = Rapns::Notification.new
    n.app = ['test']
    n.valid?
    n.errors[:app].should == []
  end
end