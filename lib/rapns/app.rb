module Rapns
  class App < ActiveRecord::Base
    self.table_name = 'rapns_apps'

    validates :key, :presence => true, :uniqueness => true
    validates :environment, :presence => true
    validates_uniqueness_of :environment, :scope => :key
    validates :certificate, :presence => true
    validates :connections, :numericality => true
  end
end