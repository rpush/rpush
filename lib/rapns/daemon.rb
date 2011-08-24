require "rapns/daemon/configuration"
require "rapns/daemon/pem"

module Rapns
  module Daemon
    def self.start(environment, options)
      Configuration.load(environment, File.join(Rails.root, "config", "rapns", "rapns.yml"))
      Pem.load(environment, File.join(Rails.root, "config", "rapns", "#{environment}.pem"))
    end
  end
end