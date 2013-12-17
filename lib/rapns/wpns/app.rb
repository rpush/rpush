module Rapns
  module Wpns
    class App < Rapns::App
      validates :client_id, :client_secret, :presence => true
    end
  end
end
