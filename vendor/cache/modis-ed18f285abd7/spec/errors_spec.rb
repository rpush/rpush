require 'spec_helper'

module ErrorsSpec
  class MockModel
    include Modis::Model

    attribute :name, :string
  end
end

describe Modis::Errors do
  let(:model) { ErrorsSpec::MockModel.new }

  it 'adds errors' do
    model.errors.add(:name, 'is not valid')
    model.errors[:name].should eq ['is not valid']
  end
end
