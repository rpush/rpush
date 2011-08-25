# rapns [![Build Status](https://secure.travis-ci.org/ileitch/rapns.png)](http://travis-ci.org/ileitch/rapns)

Easy to use library for Apple's Push Notification Service with Rails 3.

Apple recommends keeping a persistent connection open to its Push Notification Service. To achieve this rapns provides a daemon process which runs unattended in the background, sending notifications as they are created.

## Getting Started

Add rapns to your Gemfile:

  gem 'rapns'
  
Generate the migration and config:

  rails g rapns
    
Migrate:

  rake db:migrate
    



