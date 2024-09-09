# frozen_string_literal: true

module Rpush
  module Client
    module ActiveRecord
      module Wns
        class Notification < Rpush::Client::ActiveRecord::Notification
          include Rpush::Client::ActiveModel::Wns::Notification
        end
      end
    end
  end
end
