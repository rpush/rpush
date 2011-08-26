# rapns [![Build Status](https://secure.travis-ci.org/ileitch/rapns.png)](http://travis-ci.org/ileitch/rapns)

Easy to use library for Apple's Push Notification Service with Rails 3.

Apple recommends keeping a persistent connection open to its Push Notification Service. To achieve this rapns provides a daemon process which runs unattended in the background, sending notifications as they are created.

## Getting Started

Add rapns to your Gemfile:

    gem 'rapns'
  
Generate the migration, rapns.yml and migrate:

    rails g rapns
    rake db:migrate

## Generating Certificates

1. Open up Keychain Access and select the Certificates category in the sidebar.
2. Expand the disclosure arrow next to the iOS Push Services certificate you want to export.
3. Select both the certificate and private key.
4. Right click and select `Export 2 items...`.
5. Save the file as `cert.p12`, make sure the File Format is `Personal Information Exchange (p12)`.
6. Convert the certificate to a .pem, where <environment> should be `development` or `production`, depending on the certificate you exported.

    openssl pkcs12 -nodes -clcerts -in cert.p12 -out <environment>.pem 
      
7. Move the .pem file into your Rails application under config/rapns.

## Configuration

Environment configuration lives in config/rapns/rapns.yml. For common setups you probably wont need to change this file.

If you want to use rapns in environments other than development or production, you will need to create an entry for it. Simply duplicate the configuration for development and production, depending on which iOS Push Certificate you wish to use.

The `certificate` entry assumes .pem files exist under config/rapns. If your .pem files must exist in a different location, you can set `certificate` to an absolute path.
