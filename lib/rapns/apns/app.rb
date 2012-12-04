module Rapns
  module Apns
    class App < Rapns::App
      validates :environment, :presence => true, :inclusion => { :in => %w(development production) }
      validates :certificate, :presence => true
    end
  end
end