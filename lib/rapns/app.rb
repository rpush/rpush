module Rapns
  class App < ActiveRecord::Base
    self.table_name = 'rapns_apps'

    attr_accessible :name, :environment, :certificate, :password, :connections, :auth_key

    validates :name, :presence => true, :uniqueness => { :scope => [:type, :environment] }
    validates_numericality_of :connections, :greater_than => 0, :only_integer => true
  end
end
