require 'spec_helper'

module PersistenceSpec
  class MockModel
    include Modis::Model

    attribute :name, :string
  end
end

describe Modis::Persistence do
  let(:model) { PersistenceSpec::MockModel.new }

  describe 'namespaces' do
    it 'returns the namespace' do
      PersistenceSpec::MockModel.namespace.should eq 'persistence_spec:mock_model'
    end

    it 'returns the absolute namespace' do
      PersistenceSpec::MockModel.absolute_namespace.should eq 'modis:persistence_spec:mock_model'
    end

    it 'allows the namespace to be set explicitly' do
      PersistenceSpec::MockModel.namespace = 'other'
      PersistenceSpec::MockModel.absolute_namespace.should eq 'modis:other'
    end

    after { PersistenceSpec::MockModel.namespace = nil }
  end

  it 'returns a key' do
    model.save!
    model.key.should eq 'modis:persistence_spec:mock_model:1'
  end

  it 'returns a nil key if not saved' do
    model.key.should be_nil
  end

  it 'works with ActiveModel dirty tracking' do
    expect { model.name = 'Ian' }.to change(model, :changed).to(['name'])
    model.name_changed?.should be_true
  end

  it 'reset dirty tracking when saved' do
    model.name = 'Ian'
    model.name_changed?.should be_true
    model.save!
    model.name_changed?.should be_false
  end

  it 'reset dirty tracking when created' do
    model = PersistenceSpec::MockModel.create!(:name => 'Ian')
    model.name_changed?.should be_false
  end

  it 'is persisted' do
    model.persisted?.should be_true
  end

  it 'does not track the ID if the underlying Redis command failed'

  shared_examples_for 'all create methods' do
    it 'reset dirty tracking' do
      model = PersistenceSpec::MockModel.send(create_method, :name => 'Ian')
      model.name_changed?.should be_false
    end

    it 'preserves dirty state for the duration of the callback life cycle'
  end

  describe 'create' do
    let(:create_method) { :create }
    it_should_behave_like 'all create methods'
  end

  describe 'create!' do
    let(:create_method) { :create! }
    it_should_behave_like 'all create methods'
  end
end
