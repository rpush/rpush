module Rpush
  module Client
    module Mongoid
      class App
        include ::Mongoid::Document

        field :name, type: String
        field :environment, type: String
        field :certificate, type: String
        field :password, type: String
        field :connections, type: Integer, default: 1
        field :auth_key, type: String
        field :client_id, type: String
        field :client_secret, type: String

        index name: 1

        validates :name, presence: true
        validates_numericality_of :connections, greater_than: 0, only_integer: true
      end
    end
  end
end
