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
        attribute :connections, :integer, default: 1
        attribute :auth_key, :string
        attribute :client_id, :string
        attribute :client_secret, :string

        index :name

        validates :name, presence: true
        validates_numericality_of :connections, greater_than: 0, only_integer: true
      end
    end
  end
end
