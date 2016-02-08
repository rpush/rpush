module Rpush
  module Client
    module ActiveModel
      module Wns
        module Notification
          module InstanceMethods
            def alert=(value)
              return unless value
              data = self.data || {}
              data['title'] = value
              self.data = data
            end

            def skip_data_validation?
              false
            end
          end

          def self.included(base)
            base.instance_eval do
              include InstanceMethods

              validates :uri, presence: true
              validates :uri, format: { with: %r{https?://[\S]+} }
              validates :data, presence: true, unless: :skip_data_validation?
            end
          end
        end
      end
    end
  end
end
