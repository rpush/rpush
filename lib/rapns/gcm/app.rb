module Rapns
  module Gcm
    class App < Rapns::App
      validates :auth_key, :presence => true
    end
  end
end