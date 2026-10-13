require 'unit_spec_helper'

describe Rpush::MultiJsonHelper do
  let(:helper) { Object.new.extend(described_class) }

  it 'uses MultiJSON.parse when available' do
    result = double
    options = { symbolize_names: true }
    stub_const('MultiJSON', double(parse: result))

    expect(MultiJSON).to receive(:parse).with('{"key":"value"}', options).and_return(result)
    expect(helper.multi_json_load('{"key":"value"}', options)).to eq(result)
  end

  it 'uses MultiJSON.generate when available' do
    result = '{"key":"value"}'
    options = { pretty: true }
    stub_const('MultiJSON', double(generate: result))

    expect(MultiJSON).to receive(:generate).with({ key: 'value' }, options).and_return(result)
    expect(helper.multi_json_dump({ key: 'value' }, options)).to eq(result)
  end
end
