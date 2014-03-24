require 'spec_helper'

describe 'validations' do
  class TestModel
    include Modis::Model
    attribute :name, :string
    validates :name, presence: true
  end

  let(:model) { TestModel.new }

  it 'responds to valid?' do
    model.name = nil
    model.valid?.should be_false
  end

  it 'sets errors on the model' do
    model.name = nil
    model.valid?
    model.errors[:name].should eq ["can't be blank"]
  end

  describe 'save' do
    it 'returns true if the model is valid' do
      model.name = "Ian"
      model.save.should be_true
    end

    it 'returns false if the model is invalid' do
      model.name = nil
      model.save.should be_false
    end
  end

  describe 'save!' do
    it 'raises an error if the model is invalid' do
      model.name = nil
      expect do
        model.save!.should be_false
      end.to raise_error(Modis::RecordNotSaved)
    end
  end
end
