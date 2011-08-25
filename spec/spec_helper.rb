ENV["RAILS_ENV"] = "test"

require "active_record"

ActiveRecord::Base.establish_connection("adapter" => "postgresql", "database" => "rapns_test")
require "generators/templates/create_rapns_notifications"

CreateRapnsNotifications.down rescue ActiveRecord::StatementInvalid
CreateRapnsNotifications.up

Bundler.require(:default)

require "shoulda"

require "rapns"
require "rapns/daemon"



