require 'spec_helper'

describe Rpush::Daemon::ServiceConfigMethods do
  module ServiceConfigMethodsSpec
    extend Rpush::Daemon::ServiceConfigMethods
    class Delivery; end
  end

  it 'returns the delivery class' do
    ServiceConfigMethodsSpec.delivery_class.should eq ServiceConfigMethodsSpec::Delivery
  end

  it 'gets & sets loops' do
    loop_class = double
    ServiceConfigMethodsSpec.loops loop_class
    ServiceConfigMethodsSpec.loops.should eq [loop_class]
  end

  it 'returns a new dispatcher' do
    ServiceConfigMethodsSpec.dispatcher :http, an: :option
    app = double
    dispatcher = double
    Rpush::Daemon::Dispatcher::Http.should_receive(:new).with(app, ServiceConfigMethodsSpec::Delivery, an: :option).and_return(dispatcher)
    ServiceConfigMethodsSpec.new_dispatcher(app).should eq dispatcher
  end

  it 'raises a NotImplementedError for an unknown dispatcher type' do
    expect do
      ServiceConfigMethodsSpec.dispatcher :unknown
      ServiceConfigMethodsSpec.dispatcher_class
    end.to raise_error(NotImplementedError)
  end
end
