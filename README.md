# rapns [![Build Status](https://secure.travis-ci.org/ileitch/rapns.png)](http://travis-ci.org/ileitch/rapns)

Easy to use library for Apple's Push Notification Service with Rails 3.

## Features

* Works with Rails 3 and Ruby 1.9.
* Uses a daemon process to keep open a persistent connection to the Push Notification Service, as recommended by Apple.
* Uses the [enhanced binary format](http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW4) (Figure 5-2) so that delivery errors can be reported.
* Airbrake (Hoptoad) integration.
* Support for [dictionary `alert` properties](http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/ApplePushService/ApplePushService.html#//apple_ref/doc/uid/TP40008194-CH100-SW1) (Table 3-2).

## Getting Started

Add rapns to your Gemfile:

    gem 'rapns'
  
Generate the migration, rapns.yml and migrate:

    rails g rapns
    rake db:migrate

## Generating Certificates

1. Open up Keychain Access and select the `Certificates` category in the sidebar.
2. Expand the disclosure arrow next to the iOS Push Services certificate you want to export.
3. Select both the certificate and private key.
4. Right click and select `Export 2 items...`.
5. Save the file as `cert.p12`, make sure the File Format is `Personal Information Exchange (p12)`.
6. If you decide to set a password for your exported certificate, please read the Configuration section below.
7. Convert the certificate to a .pem, where <environment> should be `development` or `production`, depending on the certificate you exported.

    `openssl pkcs12 -nodes -clcerts -in cert.p12 -out <environment>.pem`
      
8. Move the .pem file into your Rails application under config/rapns.

## Configuration

Environment configuration lives in `config/rapns/rapns.yml`. For common setups you probably wont need to change this file.

If you want to use rapns in environments other than development or production, you will need to create an entry for it. Simply duplicate the configuration for development or production, depending on which iOS Push Certificate you wish to use.

The `certificate` entry assumes .pem files exist under `config/rapns`. If your .pem files must exist in a different location, you can set `certificate` to an absolute path.

If you set a password on your certificate, you'll need to set the `certificate_password` entry too.

## Running rapns

    bundle exec rapns <environment>
    
### Options

* `--foreground` will prevent rapns from forking into a daemon. Activity information will be printed to the screen.
* `--poll=SECONDS` defines how frequently to check the database for new notifications to deliver. Default is 2 seconds.

## Sending a Notification

    n = Rapns::Notification.new
    n.device_token = "934f7a..."
    n.alert = "This is the message shown on the device."
    n.badge = 1
    n.sound = "1.aiff"
    n.expiry = 1.day.to_i
    n.attributes_for_device = {"question" => nil, "answer" => 42}
    n.save!

* `sound` defaults to `1.aiff`. You can either set it to a custom .aiff file, or `nil` for no sound.
* `expiry` is the time in seconds the APNs will spend trying to deliver the notification to the device. The notification is discarded if it has not been delivered in this time. Default is 1 day.
* `attributes_for_device` is the `NSDictionary` argument passed to your iOS app in either `didFinishLaunchingWithOptions` or `didReceiveRemoteNotification`.

### Assigning a Hash to `alert`

Please refer to Apple's [documentation](http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/ApplePushService/ApplePushService.html#//apple_ref/doc/uid/TP40008194-CH100-SW1) for this feature.

Not yet implemented!