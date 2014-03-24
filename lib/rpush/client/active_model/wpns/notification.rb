module Rpush
  module Client
    module ActiveModel
      module Wpns
        module Notification
          def self.included(base)
            base.instance_eval do
              validates :uri, presence: true
              validates :uri, format: { with: /https?:\/\/[\S]+/ }
              validates :alert, presence: true
            end
          end
        end
      end
    end
  end
end
