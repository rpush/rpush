[![Build Status](https://secure.travis-ci.org/ileitch/rapns.png?branch=master)](http://travis-ci.org/ileitch/rapns)

rapns - Professional grade APNs and GCM daemon.

* Supports both APNs (iOS) and GCM (Google Cloud Messaging, Android).
* Seamless Rails integration.
* Scalable - choose the number of threads each app spawns.
* Designed for uptime - signal -HUP to add, update apps.
* Stable - reconnects database and network connections when lost.
* Works with MRI, JRuby, Rubinius 1.8 and 1.9.
* [Airbrake](http://airbrakeapp.com/) integration.

### Who uses rapns?

[GateGuru](http://gateguruapp.com) and [Desk.com](http://desk.com), among others!

*I'd love to hear if you use rapns - @ileitch on twitter.*

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
6. If you decide to set a password for your exported certificate, please read the 'Adding Apps' section below.
7. Convert the certificate to a .pem, where `<environment>` should be `development` or `production`, depending on the certificate you exported.

    `openssl pkcs12 -nodes -clcerts -in cert.p12 -out <environment>.pem`

## Create an App

<table>
    <th>
        <td>APNs</td>
        <td>GCM</td>
    </th>
    <tr>
        <td>
            <pre>
                <code>
app = Rapns::Apns::App.new
app.name = "ios_app"
app.certificate = File.read("/path/to/development.pem")
app.environment = "development"
app.password = "certificate password"
app.connections = 1
app.save!
                </code>
            </pre>
        </td>
        <td>
            <pre>
                <code>
app = Rapns::Gcm::App.new
app.name = 'android_app'
app.auth_key = "..."
app.connections = 1
app.save!
                </code>
            </pre>
        </td>
    </tr>
</table>

<table>
    <th>
        <td>APNs</td>
        <td>GCM</td>
    </th>
    <tr>
        <td>
            <pre>
                <code>
                </code>
            </pre>
        </td>
        <td>
            <pre>
                <code>
n = Rapns::Gcm::Notification.new
n.app = Rapns::Gcm::App.find_by_name("android_app")
n.registration_ids = ["..."]
n.data = {:message => "hi mom!"}
n.save!
                </code>
            </pre>
        </td>
    </tr>
</table>


## Starting the rapns Daemon

    cd /path/to/rails/app
    bundle exec rapns <Rails environment> [options]


* Install
    - Note on updates.
* Basic usage
    - Generate cert.
    - Apns, GCM
* Wiki links




==================================================================================


[![Build Status](https://secure.travis-ci.org/ileitch/rapns.png?branch=master)](http://travis-ci.org/ileitch/rapns)

# Features

* Works with Rails 3 and Ruby 1.9 & 1.8.
* Supports multiple iOS apps.
* [Add & remove apps](#hot-app-updates) without restarting or affecting the delivery of notifications to other apps.
* Uses a daemon process to keep open persistent connections to the APNs, as recommended by Apple.
* Uses the enhanced binary format so that [delivery errors can be reported](#delivery-failures).
* Records feedback from [The Feedback Service](#delivery-failures).
* [Airbrake](http://airbrakeapp.com/) (Hoptoad) integration.
* Support for [dictionary `alert` properties](#assigning-a-hash-to-alert).
* [Mobile Device Management (MDM)](#mobile-device-management)
* Stable. Reconnects to the APNs and your database if connections are lost.

### Who uses rapns?

[GateGuru](http://gateguruapp.com) and [Desk.com](http://desk.com), among others!

*I'd love to hear if you use rapns - @ileitch on twitter.*

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
6. If you decide to set a password for your exported certificate, please read the 'Adding Apps' section below.
7. Convert the certificate to a .pem, where `<environment>` should be `development` or `production`, depending on the certificate you exported.

    `openssl pkcs12 -nodes -clcerts -in cert.p12 -out <environment>.pem`

## Create an App

    app = Rapns::App.new
    app.key = "my_app"
    app.certificate = File.read("/path/to/development.pem")
    app.environment = "development"
    app.password = "certificate password"
    app.connections = 1
    app.save!

* `key` is a symbolic name to tie this app to notifications.
* `certificate` is the contents of your PEM certificate, NOT its path on disk.
* `environment` the certificate type, either `development` or `production`.
* `password` should be left blank if you did not password protect your certificate.
* `connections` (default: 1) the number of connections to keep open to the APNs. Consider increasing this if you are sending a large number of notifications to this app.

## Starting the rapns Daemon

    cd /path/to/rails/app
    bundle exec rapns <Rails environment> [options]

### Options

* `-f` `--foreground` Prevent rapns from forking into a daemon.
* `-P N` `--db-poll N` Frequency in seconds to check for new notifications. Default: 2.
* `-F N` `--feedback-poll N` Frequency in seconds to check for feedback. Default: 60.
* `-e` `--no-error-checks` Disables [error checking](#immediately-when-processing-a-notification-for-delivery) after notification delivery. You may want to disable this if you are sending a very high number of notifications.
* `-n` `--no-airbrake-notify` Disables error notifications via Airbrake.
* `-p PATH` `--pid-file PATH` Path to write PID file. Relative to Rails root unless absolute.
* `-b N` `--batch-size N` ActiveRecord batch size of notifications. Increase for possible higher throughput but higher memory footprint. Default: 5000.

## Sending a Notification

    n = Rapns::Notification.new
    n.app = "my_app"
    n.device_token = "934f7a..."
    n.alert = "This is the message shown on the device."
    n.badge = 1
    n.sound = "1.aiff"
    n.expiry = 1.day.to_i
    n.attributes_for_device = {"question" => nil, "answer" => 42}
    n.deliver_after = 1.hour.from_now
    n.save!

* `app` must match `key` on an `Rapns::App`.
* `sound` defaults to `1.aiff`. You can either set it to a custom .aiff file, or `nil` for no sound.
* `expiry` is the time in seconds the APNs (not rapns) will spend trying to deliver the notification to the device. The notification is discarded if it has not been delivered in this time. Default is 1 day.
* `attributes_for_device` is the `NSDictionary` argument passed to your iOS app in either `didFinishLaunchingWithOptions` or `didReceiveRemoteNotification`.
* `deliver_after` is not required, but may be set if you'd like to delay delivery of the notification to a specific time in the future.

### Mobile Device Management

    n = Rapns::Notification.new
    n.mdm = "magic"
    n.save!

### Assigning a Hash to alert

Please refer to Apple's [documentation](http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/ApplePushService/ApplePushService.html#//apple_ref/doc/uid/TP40008194-CH100-SW1) (Tables 3-1 and 3-2).

## Hot App Updates

If you signal the rapns process with `HUP` it will synchronize with the current `Rapns::App` configurations. This includes adding an app, removing and increasing/decreasing the number of connections an app uses.

This synchronization process does not pause the delivery of notifications to other apps.

## Logging

rapns logs activity to `rapns.log` in your Rails log directory. This is also printed to STDOUT when running in the foreground. When running as a daemon rapns does not print to STDOUT or STDERR.

## Delivery Failures

The APNs provides two mechanism for delivery failure notification:

### Immediately, when processing a notification for delivery.

Although rapns makes such errors highly unlikely due to validation, the APNs reports processing errors immediately after being sent a notification. These errors are all centred around the well-formedness of the notification payload. Should a notification be rejected due to such an error, rapns will update the following attributes on the notification and send a notification via Airbrake/Hoptoad (if enabled):

`failed` flag is set to true.
`failed_at` is set to the time of failure.
`error` is set to Apple's code for the error.
`error_description` is set to a (somewhat brief) description of the error.

rapns will not attempt to deliver the notification again.

### Via the Feedback Service.

rapns checks for feedback periodically and stores results in the `Rapns::Feedback` model. Each record contains the device token and a timestamp of when the APNs determined that the app no longer exists on the device.

It is your responsibility to avoid creating new notifications for devices that no longer have your app installed. rapns does not and will not check `Rapns::Feedback` before sending notifications.

*Note: In my testing and from other reports on the Internet, it appears you may not receive feedback when using the APNs sandbox environment.*

## Updating rapns

After updating you should run `rails g rapns` to check for any new migrations.

## Wiki

* [Deploying to Heroku](https://github.com/ileitch/rapns/wiki/Heroku)
* [Why open multiple connections to the APNs?](https://github.com/ileitch/rapns/wiki/Why-open-multiple-connections-to-the-APNs%3F)
* [Upgrading from version 2.x to 3.0](https://github.com/ileitch/rapns/wiki/Upgrading-from-version-2.x-to-3.0)

## Contributing to rapns

Fork as usual and go crazy!

When running specs, please note that the ActiveRecord adapter can be changed by setting the `ADAPTER` environment variable. For example: `ADAPTER=postgresql rake`.

Available adapters for testing are `mysql`, `mysql2` and `postgresql`.

Note that the database username is changed at runtime to be the currently logged in user's name. So if you're testing
with mysql and you're using a user named 'bob', you will need to grant a mysql user 'bob' access to the 'rapns_test'
mysql database.

### Contributors

Thank you to the following wonderful people for contributing to rapns:

* [@blakewatters](https://github.com/blakewatters)
* [@forresty](https://github.com/forresty)
* [@sjmadsen](https://github.com/sjmadsen)
* [@ivanyv](https://github.com/ivanyv)
* [@taybenlor](https://github.com/taybenlor)
* [@tompesman](https://github.com/tompesman)
* [@EpicDraws](https://github.com/EpicDraws)
* [@dei79](https://github.com/dei79)
* [@adorr](https://github.com/adorr)
* [@mattconnolly](https://github.com/mattconnolly)
* [@emeitch](https://github.com/emeitch)
