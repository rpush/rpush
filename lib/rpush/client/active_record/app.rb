module Rpush
  module Client
    module ActiveRecord
      class App < ::ActiveRecord::Base
        self.table_name = 'rpush_apps'

        if Rpush.attr_accessible_available?
          attr_accessible :name, :environment, :certificate, :password, :connections, :auth_key, :client_id, :client_secret
        end

        has_many :notifications, class_name: 'Rpush::Client::ActiveRecord::Notification', dependent: :destroy

        validates :name, presence: true, uniqueness: { scope: [:type, :environment] }
      end
    end
  end
end
