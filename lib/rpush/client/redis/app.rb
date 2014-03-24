module Rpush
  module Client
    module Redis
      class App
        include Modis::Model
        self.namespace = 'apps'

        attribute :name, :string
        attribute :environment, :string
        attribute :certificate, :string
        attribute :password, :string
        attribute :connections, :integer
        attribute :auth_key, :string
        attribute :client_id, :string
        attribute :client_secret, :string

        validates :name, presence: true
        validates_numericality_of :connections, greater_than: 0, only_integer: true

        def service_name
          raise NotImplementedError
        end
      end
    end
  end
end

