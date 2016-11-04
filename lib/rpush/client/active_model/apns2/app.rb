module Rpush
  module Client
    module ActiveModel
      module Apns2
        module App
          extend Rpush::Client::ActiveModel::Apns::App

          def service_name
            'apns2'
          end
        end
      end
    end
  end
end
