module Rapns
  module Gcm
    class App < Rapns::App
      validates :registration_id, :presence => true
    end
  end
end