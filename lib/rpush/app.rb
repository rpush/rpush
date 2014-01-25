module Rpush
  class App < ActiveRecord::Base
    self.table_name = 'rpush_apps'

    if Rpush.attr_accessible_available?
      attr_accessible :name, :environment, :certificate, :password, :connections, :auth_key, :client_id, :client_secret
    end

    has_many :notifications, :class_name => 'Rpush::Notification', :dependent => :destroy

    validates :name, :presence => true, :uniqueness => { :scope => [:type, :environment] }
    validates_numericality_of :connections, :greater_than => 0, :only_integer => true

    def service_name
      raise NotImplementedError
    end
  end
end
