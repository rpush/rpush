[![Build Status](https://secure.travis-ci.org/rpush/rpush.svg?branch=master)](http://travis-ci.org/rpush/rpush)
[![Code Climate](https://codeclimate.com/github/rpush/rpush/badges/gpa.svg)](https://codeclimate.com/github/rpush/rpush)
[![Test Coverage](https://codeclimate.com/github/rpush/rpush/badges/coverage.svg)](https://codeclimate.com/github/rpush/rpush)
[![Gem Version](https://badge.fury.io/rb/rpush.svg)](http://badge.fury.io/rb/rpush)

<img src="https://raw.github.com/rpush/rpush/master/logo.png" align="right" width="200px" />

### Rpush. The push notification service for Ruby.

* Supported services:
  * [**Apple Push Notification Service**](#apple-push-notification-service)
  * [**Google Cloud Messaging**](#google-cloud-messaging)
  * [**Amazon Device Messaging**](#amazon-device-messaging)
  * [**Windows Phone Push Notification Service**](#windows-phone-notification-service)

* Supported storage backends:
  * **ActiveRecord**
  * **Redis**
  * More coming!

* Seamless Rails integration (3 & 4) .
* Scales vertically (threading) and horizontally (multiple processes).
* Designed for uptime - new apps are loaded automatically, signal `HUP` to update running apps.
* Run as a daemon or inside an [existing process](https://github.com/rpush/rpush/wiki/Embedding-API).
* Use in a scheduler for low-workload deployments ([Push API](https://github.com/rpush/rpush/wiki/Push-API)).
* Hooks for fine-grained instrumentation and error handling ([Reflection API](https://github.com/rpush/rpush/wiki/Reflection-API)).
* Works with MRI, JRuby and Rubinius.


### Getting Started

Add it to your Gemfile:

```ruby
gem 'rpush'
```

Generate the migrations, rpush.rb and migrate:

```
rails g rpush
rake db:migrate
```

### Create an App & Notification

#### Apple Push Notification Service

If this is your first time using the APNs, you will need to generate SSL certificates. See [Generating Certificates](https://github.com/rpush/rpush/wiki/Generating-Certificates) for instructions.

```ruby
app = Rpush::Apns::App.new
app.name = "ios_app"
app.certificate = File.read("/path/to/sandbox.pem")
app.environment = "sandbox" # APNs environment.
app.password = "certificate password"
app.connections = 1
app.save!
```

```ruby
n = Rpush::Apns::Notification.new
n.app = Rpush::Apns::App.find_by_name("ios_app")
n.device_token = "..."
n.alert = "hi mom!"
n.data = { foo: :bar }
n.save!
```

You should also implement the [ssl_certificate_will_expire](https://github.com/rpush/rpush/wiki/Reflection-API) reflection to monitor when your certificate is due to expire.

#### Google Cloud Messaging

```ruby
app = Rpush::Gcm::App.new
app.name = "android_app"
app.auth_key = "..."
app.connections = 1
app.save!
```

```ruby
n = Rpush::Gcm::Notification.new
n.app = Rpush::Gcm::App.find_by_name("android_app")
n.registration_ids = ["token", "..."]
n.data = { message: "hi mom!" }
n.save!
```

GCM also requires you to respond to [Canonical IDs](https://github.com/rpush/rpush/wiki/Canonical-IDs).

#### Amazon Device Messaging

```ruby
app = Rpush::Adm::App.new
app.name = "kindle_app"
app.client_id = "..."
app.client_secret = "..."
app.connections = 1
app.save!
```

```ruby
n = Rpush::Adm::Notification.new
n.app = Rpush::Adm::App.find_by_name("kindle_app")
n.registration_ids = ["..."]
n.data = { message: "hi mom!"}
n.collapse_key = "Optional consolidationKey"
n.save!
```

For more documentation on [ADM](https://developer.amazon.com/sdk/adm.html).

#### Windows Phone Notification Service

```ruby
app = Rpush::Wpns::App.new
app.name = "windows_phone_app"
app.connections = 1
app.save!
```

```ruby
n = Rpush::Wpns::Notification.new
n.app = Rpush::Wpns::App.find_by_name("windows_phone_app")
n.uri = "http://..."
n.alert = "..."
n.save!
```

### Running Rpush

It is recommended to run Rpush as a separate process in most cases, though embedding and manual modes are provided for low-workload environments.

#### As a daemon (recommended):

    cd /path/to/rails/app
    rpush <Rails environment> [options]

#### Embedded inside an existing process

```ruby
# Call this during startup of your application, for example, by adding it to the end of config/rpush.rb
Rpush.embed
```

See [Embedding API](https://github.com/rpush/rpush/wiki/Embedding-API) for more details.

#### Manually (in a scheduler)

```ruby
Rpush.push
Rpush.apns_feedback
```

See [Push API](https://github.com/rpush/rpush/wiki/Push-API) for more details.

### Configuration

See [Configuration](https://github.com/rpush/rpush/wiki/Configuration) for a list of options, or run `rpush --help`.

### Updating Rpush

If you're using ActiveRecord, you should run `rails g rpush` after upgrading Rpush to check for any new migrations.

### Wiki

### General
* [Configuration](https://github.com/rpush/rpush/wiki/Configuration)
* [Moving from Rapns](https://github.com/rpush/rpush/wiki/Moving-from-Rapns-to-Rpush)
* [Deploying to Heroku](https://github.com/rpush/rpush/wiki/Heroku)
* [Hot App Updates](https://github.com/rpush/rpush/wiki/Hot-App-Updates)
* [Signals](https://github.com/rpush/rpush/wiki/Signals)
* [Reflection API](https://github.com/rpush/rpush/wiki/Reflection-API)
* [Push API](https://github.com/rpush/rpush/wiki/Push-API)
* [Embedding API](https://github.com/rpush/rpush/wiki/Embedding-API)
* [Implementing your own storage backend](https://github.com/rpush/rpush/wiki/Implementing-your-own-storage-backend)
* [Upgrading from 2.x to 3.0](https://github.com/rpush/rpush/wiki/Upgrading-from-version-2.x-to-3.0)

### Apple Push Notification Service
* [Generating Certificates](https://github.com/rpush/rpush/wiki/Generating-Certificates)
* [Advanced APNs Features](https://github.com/rpush/rpush/wiki/Advanced-APNs-Features)
* [APNs Delivery Failure Handling](https://github.com/rpush/rpush/wiki/APNs-Delivery-Failure-Handling)
* [Why open multiple connections to the APNs?](https://github.com/rpush/rpush/wiki/Why-open-multiple-connections-to-the-APNs%3F)
* [Silent failures might be dropped connections](https://github.com/rpush/rpush/wiki/Dropped-connections)

### Google Cloud Messaging
* [Notification Options](https://github.com/rpush/rpush/wiki/GCM-Notification-Options)
* [Canonical IDs](https://github.com/rpush/rpush/wiki/Canonical-IDs)
* [Delivery Failures & Retries](https://github.com/rpush/rpush/wiki/Delivery-Failures-&-Retries)

### Contributing

Fork as usual and go crazy!

When running specs, please note that the ActiveRecord adapter can be changed by setting the `ADAPTER` environment variable. For example: `ADAPTER=postgresql rake`.

Available adapters for testing are `mysql`, `mysql2` and `postgresql`.

Note that the database username is changed at runtime to be the currently logged in user's name. So if you're testing
with mysql and you're using a user named 'bob', you will need to grant a mysql user 'bob' access to the 'rpush_test'
mysql database.
