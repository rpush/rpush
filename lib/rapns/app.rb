module Rapns
  class App < ActiveRecord::Base
    self.table_name = 'rapns_apps'

    validates :key, :presence => true, :uniqueness => true
    validates_numericality_of :connections, :greater_than => 0, :only_integer => true

    def new_runner
      raise NotImplementedError
    end
  end
end