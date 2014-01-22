require 'rails'

module MyPlugin
  class Railtie < Rails::Railtie
    railtie_name :rapns

    rake_tasks do
      load "tasks/rapns.rake"
    end
  end
end
