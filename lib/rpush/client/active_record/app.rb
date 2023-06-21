module Rpush
  module Client
    module ActiveRecord
      class App < ::ActiveRecord::Base
        self.table_name = 'rpush_apps'

        has_many :notifications, class_name: 'Rpush::Client::ActiveRecord::Notification', dependent: :destroy
      end
    end
  end
end
