module Rpush
  module Client
    module Mongoid
      module Adm
        class Notification < Rpush::Client::Mongoid::Notification
          include Rpush::Client::ActiveModel::Adm::Notification
        end
      end
    end
  end
end
