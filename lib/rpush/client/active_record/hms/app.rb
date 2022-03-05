module Rpush
  module Client
    module ActiveRecord
      module Hms
        class App < Rpush::Client::ActiveRecord::App
          include Rpush::Client::ActiveModel::Hms::App
        end
      end
    end
  end
end
