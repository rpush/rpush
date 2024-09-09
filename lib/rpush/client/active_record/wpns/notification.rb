# frozen_string_literal: true

module Rpush
  module Client
    module ActiveRecord
      module Wpns
        class Notification < Rpush::Client::ActiveRecord::Notification
          include Rpush::Client::ActiveModel::Wpns::Notification
        end
      end
    end
  end
end
