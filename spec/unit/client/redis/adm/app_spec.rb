# frozen_string_literal: true

require 'unit_spec_helper'

if redis?
  describe Rpush::Client::Redis::Adm::App do
    it_behaves_like 'Rpush::Client::Adm::App'
  end
end
