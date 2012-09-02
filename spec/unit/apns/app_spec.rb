require "unit_spec_helper"

describe Rapns::Apns::App do
  it { should validate_presence_of(:environment) }
  it { should ensure_inclusion_of(:environment).in_array(['development', 'production']) }
  it { should validate_presence_of(:certificate) }
end