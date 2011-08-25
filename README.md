rapns [Test Status](https://secure.travis-ci.org/ileitch/rapns.png)
=====

Easy to use library for Apple's Push Notification Service with Rails 3.

Apple recommends keeping a persistent connection open to its Push Notification Service. To achieve this rapns provides a daemon process which runs unattended in the background, sending notifications as they are created. From the perspective of where you will be creating your notification records, this functionality is transparent. All you need to do is ensure the daemon is kept running by using a monitoring tool such a Monit or God. Example configurations for both are shown below.

Getting Started
---------------

Add rapns to your Gemfile:
    gem 'rapns'
    
Run bundler:
    bundle
    
Generate the migration for rapns_notifications:
    rails g rapns
    
Migrate:
    rake db:migrate
    
Installing your Push Certificates
---------------------------------




