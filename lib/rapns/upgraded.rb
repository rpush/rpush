module Rapns
  module Upgraded
    def self.check(options = {})
      count = 0

      begin
        count = Rapns::App.count
      rescue ActiveRecord::StatementInvalid
        puts "!!!! RAPNS NOT STARTED !!!!"
        puts
        puts "As of version v2.0.0 apps are configured in the database instead of rapns.yml."
        puts "Please run 'rails g rapns' to generate the new migrations and create your app."
        puts "See https://github.com/ileitch/rapns for further instructions."
        puts
        exit 1 if options[:exit]
      end

      if count == 0
        Rapns.logger.warn("You have not created an app yet. See https://github.com/ileitch/rapns for instructions.")
      end

      if File.exists?(File.join(Rails.root, 'config', 'rapns', 'rapns.yml'))
        Rapns.logger.warn(<<-EOS)
Since 2.0.0 rapns uses command-line options and a Ruby based configuration file.
Please run 'rails g rapns' to generate a new configuration file into config/initializers.
Remove config/rapns/rapns.yml to avoid this warning.
        EOS
      end
    end
  end
end
