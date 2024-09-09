# frozen_string_literal: true

module Rpush
  module Client
    module Redis
      module Wpns
        class Notification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Wpns::Notification
        end
      end
    end
  end
end
