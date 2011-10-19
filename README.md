# rapns [![Build Status](https://secure.travis-ci.org/ileitch/rapns.png)](http://travis-ci.org/ileitch/rapns)

Easy to use library for Apple's Push Notification Service with Rails 3.

## Features

* Works with Rails 3 and Ruby 1.9.
* Uses a daemon process to keep open a persistent connection to the Push Notification Service, as recommended by Apple.
* Uses the [enhanced binary format](http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW4) (Figure 5-2) so that delivery errors can be reported.
* [Airbrake](http://airbrakeapp.com/) (Hoptoad) integration.
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
7. Convert the certificate to a .pem, where `<environment>` should be `development` or `production`, depending on the certificate you exported.

    `openssl pkcs12 -nodes -clcerts -in cert.p12 -out <environment>.pem`
      
8. Move the .pem file into your Rails application under `config/rapns`.

## Configuration

Environment configuration lives in `config/rapns/rapns.yml`. For common setups you probably wont need to change this file.

If you want to use rapns in environments other than development or production, you will need to create an entry for it. Simply duplicate the configuration for development or production, depending on which iOS Push Certificate you wish to use.

### Options:

* `host` the APNs host to connect to, either `gateway.sandbox.push.apple.com` or `gateway.sandbox.push.apple.com`.
* `port` the APNs port. Currently `2195` for both hosts.
* `certificate` The path to your .pem certificate, `config/rapns` is automatically checked if a relative path is given.
* `certificate_password` (default: blank) the password you used when exporting your certificate, if any.
* `airbrake_notify` (default: true) Enables/disables error notifications via Airbrake.
* `poll` (default: 2) Frequency in seconds to check for new notifications to deliver.
* `connections` (default: 3) the number of connections to keep open to the APNs. Consider increasing this if you are sending a very large number of notifications.
* `pid_file` (default: blank) the file that rapns will write its process ID to. Paths are relative to your project's RAILS_ROOT unless an absolute path is given.

## Starting the rapns Daemon

    cd /path/to/rails/app
    bundle exec rapns <Rails environment>
    
### Options

* `--foreground` will prevent rapns from forking into a daemon. Activity information will be printed to the screen.

## Sending a Notification

    n = Rapns::Notification.new
    n.device_token = "934f7a..."
    n.alert = "This is the message shown on the device."
    n.badge = 1
    n.sound = "1.aiff"
    n.expiry = 1.day.to_i
    n.attributes_for_device = {"question" => nil, "answer" => 42}
    n.deliver_after = 1.hour.from_now
    n.save!

* `sound` defaults to `1.aiff`. You can either set it to a custom .aiff file, or `nil` for no sound.
* `expiry` is the time in seconds the APNs (not rapns) will spend trying to deliver the notification to the device. The notification is discarded if it has not been delivered in this time. Default is 1 day.
* `attributes_for_device` is the `NSDictionary` argument passed to your iOS app in either `didFinishLaunchingWithOptions` or `didReceiveRemoteNotification`.
* `deliver_after` is not required, but may be set if you'd like to delay delivery of the notification to a specific time in the future.

### Assigning a Hash to alert

Please refer to Apple's [documentation](http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/ApplePushService/ApplePushService.html#//apple_ref/doc/uid/TP40008194-CH100-SW1) (Tables 3-1 and 3-2).

Not yet implemented!

## Delivery Failures

The APN service provides two mechanism for delivery failure notification:

### Immediately, when processing a notification for delivery.

Although rapns makes such errors highly unlikely due to validation, the APNs reports processing errors immediately after being sent a notification. These errors are all centred around the well-formedness of the notification payload. Should a notification be rejected due to such an error, rapns will update the following attributes on the notification and send a notification via Airbrake/Hoptoad (if enabled):

`failed` flag is set to true.
`failed_at` is set to the time of failure.
`error` is set to Apple's code for the error.
`error_description` is set to a (somewhat brief) description of the error.

rapns will not attempt to deliver the notification again. 

### Via the Feedback Service.

Not implemented yet!

## Contributing to rapns

Fork as usual and go crazy!

When running specs, please note that the ActiveRecord adapter can be changed by setting the `ADAPTER` environment variable. For example: `ADAPTER=postgresql rake`.

Available adapters for testing are `mysql`, `mysql2` and `postgresql`.