ENV["RAILS_ENV"] = "test"

Bundler.require(:default)

require "shoulda"

require "rapns"
require "generators/templates/create_rapns_notifications"

ActiveRecord::Base.establish_connection("adapter" => "postgresql", "database" => "rapns_test")

CreateRapnsNotifications.down rescue ActiveRecord::StatementInvalid
CreateRapnsNotifications.up