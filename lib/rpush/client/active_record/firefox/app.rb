module Rpush
  module Client
    module ActiveRecord
      module Firefox
        class App < Rpush::Client::ActiveRecord::App
          def service_name
            'firefox'
          end
        end
      end
    end
  end
end
