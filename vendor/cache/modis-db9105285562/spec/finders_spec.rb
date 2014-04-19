require 'spec_helper'

module FindersSpec
  class User
    include Modis::Model
    self.namespace = 'users'

    attribute :name, :string
    attribute :age, :integer
  end

  class Consumer < User
  end

  class Producer < User
  end
end

describe Modis::Finders do
  let!(:model) { FindersSpec::User.create!(name: 'Ian', age: 28) }
  let(:found) { FindersSpec::User.find(model.id) }

  it 'finds by ID' do
    found.id.should eq model.id
    found.name.should eq model.name
    found.age.should eq model.age
  end

  it 'raises an error if the record could not be found' do
    expect do
      FindersSpec::User.find(model.id + 1)
    end.to raise_error(Modis::RecordNotFound, "Couldn't find FindersSpec::User with id=#{model.id + 1}")
  end

  it 'does not flag an attribute as dirty on a found instance' do
    found.id_changed?.should be_false
  end

  describe 'all' do
    it 'returns all records' do
      m2 = FindersSpec::User.create!(name: 'Tanya', age: 30)
      m3 = FindersSpec::User.create!(name: 'Kyle', age: 32)

      FindersSpec::User.all.should == [model, m2, m3]
    end

    it 'does not return a destroyed record' do
      model.destroy
      FindersSpec::User.all.should == []
    end
  end

  it 'identifies a found record as not being new' do
    found.new_record?.should be_false
  end

  describe 'Single Table Inheritance' do
    it 'returns the correct namespace' do
      FindersSpec::Consumer.namespace.should eq 'users'
      FindersSpec::Consumer.absolute_namespace.should eq 'modis:users'
      FindersSpec::Producer.namespace.should eq 'users'
      FindersSpec::Producer.absolute_namespace.should eq 'modis:users'
    end

    it 'returns instances of the correct class' do
      FindersSpec::Consumer.create!(name: 'Kyle')
      FindersSpec::Producer.create!(name: 'Tanya')

      models = FindersSpec::User.all

      ian = models.find { |model| model.name == 'Ian' }
      kyle = models.find { |model| model.name == 'Kyle' }
      tanya = models.find { |model| model.name == 'Tanya' }

      ian.should be_kind_of(FindersSpec::User)
      kyle.should be_kind_of(FindersSpec::Consumer)
      tanya.should be_kind_of(FindersSpec::Producer)

      FindersSpec::User.find(ian.id).should be_kind_of(FindersSpec::User)
      FindersSpec::User.find(kyle.id).should be_kind_of(FindersSpec::Consumer)
      FindersSpec::User.find(tanya.id).should be_kind_of(FindersSpec::Producer)
    end
  end
end
