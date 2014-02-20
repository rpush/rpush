[![Build Status](https://secure.travis-ci.org/rpush/rpush.png?branch=master)](http://travis-ci.org/rpush/rpush)
[![Code Climate](https://codeclimate.com/github/rpush/rpush.png)](https://codeclimate.com/github/rpush/rpush)
[![Coverage Status](https://coveralls.io/repos/rpush/rpush/badge.png?branch=master)](https://coveralls.io/r/rpush/rpush?branch=master)
[![Gem Version](https://badge.fury.io/rb/rpush.png)](http://badge.fury.io/rb/rpush)

<img src="https://raw.github.com/rpush/rpush/master/logo.png" align="right" width="200px" />

### Rpush. The push notification service for Ruby.

* Supports:
  * **Apple Push Notification Service**
  * **Google Cloud Messaging**
  * **Amazon Device Messaging**
  * **Windows Phone Push Notification Service**.
* Seamless Rails (3, 4) integration.
* Scalable - choose the number of persistent connections for each app.
* Designed for uptime - signal -HUP to add, update apps.
* Run as a daemon or inside an [existing processs](https://github.com/rpush/rpush/wiki/Embedding-API).
* Use in a scheduler for low-workload deployments ([Push API](https://github.com/rpush/rpush/wiki/Push-API)).
* Hooks for fine-grained instrumentation and error handling ([Reflection API](https://github.com/rpush/rpush/wiki/Reflection-API)).
* Works with MRI, JRuby, Rubinius 1.9, 2.0, 2.1.


### Getting Started

Add it to your Gemfile:

```ruby
gem 'rpush'
```

Generate the migrations, rpush.yml and migrate:

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
n.attributes_for_device = {:foo => :bar}
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
n.registration_ids = ["..."]
n.data = {:message => "hi mom!"}
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
n.data = {:message => "hi mom!"}
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

### Starting Rpush

As a daemon:

    cd /path/to/rails/app
    rpush <Rails environment> [options]

Inside an existing process (see [Embedding API](https://github.com/rpush/rpush/wiki/Embedding-API)):

```ruby
Rpush.embed
```

*Please note that only ever a single instance of Rpush should be running.*

In a scheduler (see [Push API](https://github.com/rpush/rpush/wiki/Push-API)):

```ruby
Rpush.push
Rpush.apns_feedback
```

See [Configuration](https://github.com/rpush/rpush/wiki/Configuration) for a list of options, or run `rpush --help`.

### Updating Rpush

After updating you should run `rails g rpush` to check for any new migrations.

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
