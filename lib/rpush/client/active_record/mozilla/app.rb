module Rpush
  module Client
    module ActiveRecord
      module Mozilla
        class App < Rpush::Client::ActiveRecord::App
          def service_name
            'mozilla'
          end
        end
      end
    end
  end
end
