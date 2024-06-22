module Rpush
  module Client
    module ActiveRecord
      module Fcm
        class App < Rpush::Client::ActiveRecord::App
          include Rpush::Client::ActiveModel::Fcm::App
        end
      end
    end
  end
end
