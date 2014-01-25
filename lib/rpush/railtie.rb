require 'rails'

module MyPlugin
  class Railtie < Rails::Railtie
    railtie_name :rpush

    rake_tasks do
      load "tasks/rpush.rake"
    end
  end
end
