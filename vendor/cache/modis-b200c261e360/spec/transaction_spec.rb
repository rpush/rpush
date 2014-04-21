require 'spec_helper'

module TransactionSpec
  class MockModel
    include Modis::Model
  end
end

describe Modis::Transaction do
  it 'yields the block in a transaction' do
    Modis.redis.should_receive(:multi).and_yield
    TransactionSpec::MockModel.transaction {}
  end
end
