require 'spec_helper'

module AttributesSpec
  class MockModel
    include Modis::Model

    attribute :name, :string, default: 'Janet'
    attribute :age, :integer, default: 60
    attribute :percentage, :float
    attribute :created_at, :timestamp
    attribute :flag, :boolean
    attribute :array, :array
    attribute :hash, :hash
    attribute :hash_strict, :hash, strict: true
    attribute :hash_not_strict, :hash, strict: false
  end
end

describe Modis::Attributes do
  let(:model) { AttributesSpec::MockModel.new }

  it 'defines attributes' do
    model.name = 'bar'
    model.name.should == 'bar'
  end

  it 'applies an default value' do
    model.name.should eq 'Janet'
    model.age.should eq 60
  end

  it 'does not mark an attribute with a default as dirty' do
    model.name_changed?.should be_false
  end

  it 'raises an error for an unsupported attribute type' do
    expect do
      class AttributesSpec::MockModel
        attribute :unsupported, :symbol
      end
    end.to raise_error(Modis::UnsupportedAttributeType)
  end

  it 'assigns attributes' do
    model.assign_attributes(name: 'bar')
    model.name.should eq 'bar'
  end

  it 'does not attempt to assign attributes that are not defined on the model' do
    model.assign_attributes(missing_attr: 'derp')
    model.respond_to?(:missing_attr).should be_false
  end

  it 'allows an attribute to be nilled' do
    model.name = nil
    model.save!
    model.class.find(model.id).name.should be_nil
  end

  describe ':string type' do
    it 'is coerced' do
      model.name = 'Ian'
      model.save!
      found = AttributesSpec::MockModel.find(model.id)
      found.name.should eq 'Ian'
    end
  end

  describe ':integer type' do
    it 'is coerced' do
      model.age = 18
      model.save!
      found = AttributesSpec::MockModel.find(model.id)
      found.age.should eq 18
    end
  end

  describe ':float type' do
    it 'is coerced' do
      model.percentage = 18.6
      model.save!
      found = AttributesSpec::MockModel.find(model.id)
      found.percentage.should eq 18.6
    end

    it 'coerces a string representation to Float' do
      model.percentage = '18.6'
      model.save!
      found = AttributesSpec::MockModel.find(model.id)
      found.percentage.should eq 18.6
    end
  end

  describe ':timestamp type' do
    it 'is coerced' do
      now = Time.now
      model.created_at = now
      model.save!
      found = AttributesSpec::MockModel.find(model.id)
      found.created_at.should be_kind_of(Time)
      found.created_at.to_s.should eq now.to_s
    end

    it 'coerces a string representation to Time' do
      now = Time.now
      model.created_at = now.to_s
      model.save!
      found = AttributesSpec::MockModel.find(model.id)
      found.created_at.should be_kind_of(Time)
      found.created_at.to_s.should eq now.to_s
    end
  end

  describe ':boolean type' do
    it 'is coerced' do
      model.flag = 'true'
      model.save!
      found = AttributesSpec::MockModel.find(model.id)
      found.flag.should eq true
    end

    it 'raises an error if assigned a non-boolean value' do
      expect { model.flag = 'unf!' }.to raise_error(Modis::AttributeCoercionError)
    end
  end

  describe ':array type' do
    it 'is coerced' do
      model.array = [1, 2, 3]
      model.save!
      found = AttributesSpec::MockModel.find(model.id)
      found.array.should eq [1, 2, 3]
    end

    it 'raises an error when assigned another type' do
      expect { model.array = {foo: :bar} }.to raise_error(Modis::AttributeCoercionError)
    end

    it 'does not raise an error when assigned a JSON array string' do
      expect { model.array = "[1,2,3]" }.to_not raise_error
    end

    it 'does not raise an error when a JSON string does not deserialize to an Array' do
      expect { model.array = "{\"foo\":\"bar\"}" }.to raise_error(Modis::AttributeCoercionError)
    end
  end

  describe ':hash type' do
    it 'is coerced' do
      model.hash = {foo: :bar}
      model.save!
      found = AttributesSpec::MockModel.find(model.id)
      found.hash.should eq({'foo' => 'bar'})
    end

    describe 'strict: true' do
      it 'raises an error if the value cannot be decoded on assignment' do
        expect { model.hash_strict = "test" }.to raise_error(MultiJson::ParseError)
      end

      it 'does not raise an error if the value can be decoded on assignment' do
        expect { model.hash_strict = "{\"foo\":\"bar\"}" }.to_not raise_error
      end
    end

    describe 'strict: false' do
      it 'returns the value if it cannot be decoded' do
        model.write_attribute(:hash_not_strict, "test")
        model.save!
        found = AttributesSpec::MockModel.find(model.id)
        found.hash_not_strict.should eq "test"
      end

      it 'does not raise an error when assigned another type' do
        expect { model.hash_not_strict = "test" }.to_not raise_error
      end
    end
  end
end
