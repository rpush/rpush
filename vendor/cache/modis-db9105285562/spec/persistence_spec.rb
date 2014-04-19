require 'spec_helper'

module PersistenceSpec
  class MockModel
    include Modis::Model

    attribute :name, :string, default: 'Ian'
    attribute :age, :integer
    validates :name, presence: true

    before_create :test_before_create
    after_create :test_after_create

    before_update :test_before_update
    after_update :test_after_update

    before_save :test_before_save
    after_save :test_after_save

    def called_callbacks
      @called_callbacks ||= []
    end

    def test_after_create
      called_callbacks << :test_after_create
    end

    def test_before_create
      called_callbacks << :test_before_create
    end

    def test_after_update
      called_callbacks << :test_after_update
    end

    def test_before_update
      called_callbacks << :test_before_update
    end

    def test_after_save
      called_callbacks << :test_after_save
    end

    def test_before_save
      called_callbacks << :test_before_save
    end
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
    expect { model.name = 'Kyle' }.to change(model, :changed).to(['name'])
    model.name_changed?.should be_true
  end

  it 'resets dirty tracking when saved' do
    model.name = 'Kyle'
    model.name_changed?.should be_true
    model.save!
    model.name_changed?.should be_false
  end

  it 'resets dirty tracking when created' do
    model = PersistenceSpec::MockModel.create!(name: 'Ian')
    model.name_changed?.should be_false
  end

  it 'is persisted' do
    model.persisted?.should be_true
  end

  it 'does not track the ID if the underlying Redis command failed'

  it 'does not perform validation if validate: false' do
    model.name = nil
    model.valid?.should be_false
    expect { model.save!(validate: false) }.to_not raise_error
    model.reload
    model.name.should be_nil

    model.save(validate: false).should be_true
  end

  describe 'an existing record' do
    it 'only updates dirty attributes'
  end

  describe 'reload' do
    it 'reloads attributes' do
      model.save!
      model2 = model.class.find(model.id)
      model2.name = 'Changed'
      model2.save!
      expect { model.reload }.to change(model, :name).to('Changed')
    end

    it 'resets dirty tracking' do
      model.save!
      model.name = 'Foo'
      model.name_changed?.should be_true
      model.reload
      model.name_changed?.should be_false
    end

    it 'raises an error if the record has not been saved' do
      expect { model.reload }.to raise_error(Modis::RecordNotFound, "Couldn't find PersistenceSpec::MockModel without an ID")
    end
  end

  describe 'callbacks' do
    it 'preserves dirty state for the duration of the callback life cycle'
    it 'halts the chain if a callback returns false'

    describe 'a new record' do
      it 'calls the before_create callback' do
        model.save!
        model.called_callbacks.should include(:test_before_create)
      end

      it 'calls the after create callback' do
        model.save!
        model.called_callbacks.should include(:test_after_create)
      end
    end

    describe 'an existing record' do
      before { model.save! }

      it 'calls the before_update callback' do
        model.save!
        model.called_callbacks.should include(:test_before_update)
      end

      it 'calls the after update callback' do
        model.save!
        model.called_callbacks.should include(:test_after_update)
      end
    end

    it 'calls the before_save callback' do
      model.save!
      model.called_callbacks.should include(:test_before_save)
    end

    it 'calls the after save callback' do
      model.save!
      model.called_callbacks.should include(:test_after_save)
    end
  end

  describe 'create' do
    it 'resets dirty tracking' do
      model = PersistenceSpec::MockModel.create(name: 'Ian')
      model.name_changed?.should be_false
    end

    describe 'a valid model' do
      it 'returns the created model'
    end

    describe 'an invalid model' do
      it 'returns the unsaved model'
    end
  end

  describe 'update_attribute' do
    it 'does not perform validation' do
      model.name = nil
      model.valid?.should be_false
      model.name = 'Test'
      model.update_attribute(:name, nil)
    end

    it 'invokes callbacks' do
      model.update_attribute(:name, 'Derp')
      model.called_callbacks.should_not be_empty
    end

    it 'updates all dirty attributes' do
      model.age = 29
      model.update_attribute(:name, 'Derp')
      model.reload
      model.age.should eq 29
    end
  end

  describe 'update_attributes!' do
it 'updates the given attributes' do
      model.update_attributes!(name: 'Derp', age: 29)
      model.reload
      model.name.should eq 'Derp'
      model.age.should eq 29
    end

    it 'invokes callbacks' do
      model.update_attributes!(name: 'Derp')
      model.called_callbacks.should_not be_empty
    end

    it 'updates all dirty attributes' do
      model.age = 29
      model.update_attributes!(name: 'Derp')
      model.reload
      model.age.should eq 29
    end

    it 'raises an error if the model is invalid' do
      expect do
        model.update_attributes!(name: nil).should be_false
        end.to raise_error(Modis::RecordInvalid)
    end
  end

  describe 'update_attributes' do
    it 'updates the given attributes' do
      model.update_attributes(name: 'Derp', age: 29)
      model.reload
      model.name.should eq 'Derp'
      model.age.should eq 29
    end

    it 'invokes callbacks' do
      model.update_attributes(name: 'Derp')
      model.called_callbacks.should_not be_empty
    end

    it 'updates all dirty attributes' do
      model.age = 29
      model.update_attributes(name: 'Derp')
      model.reload
      model.age.should eq 29
    end

    it 'returns false if the model is invalid' do
      model.update_attributes(name: nil).should be_false
    end
  end
end
