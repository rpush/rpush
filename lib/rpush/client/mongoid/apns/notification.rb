module Rpush
  module Client
    module Mongoid
      module Apns
        class Notification < Rpush::Client::Mongoid::Notification
          include Rpush::Client::ActiveModel::Apns::Notification

          def to_binary(options = {})
            super(options.merge(id_attribute: :integer_id))
          end
        end
      end
    end
  end
end
