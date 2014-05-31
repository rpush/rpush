 require 'unit_spec_helper'

 describe Rpush do
   it 'yields reflections for configuration' do
     did_yield = false
     Rpush.reflect { did_yield = true }
     did_yield.should be_true
   end

   it 'returns all reflections' do
     Rpush.reflections.should be_kind_of(Rpush::Reflections)
   end
 end

 describe Rpush::Reflections do
   it 'dispatches the given reflection' do
     did_yield = false
     Rpush.reflect do |on|
       on.error { did_yield = true }
     end
     Rpush.reflections.__dispatch(:error)
     did_yield.should be_true
   end

   it 'raises an error when trying to dispatch and unknown reflection' do
     expect do
       Rpush.reflections.__dispatch(:unknown)
     end.to raise_error(Rpush::Reflections::NoSuchReflectionError)
   end
 end
