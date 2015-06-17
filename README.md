[![Gem Version](https://badge.fury.io/rb/rpush.svg)](http://badge.fury.io/rb/rpush)
[![Join the chat at https://gitter.im/rpush/rpush](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/rpush/rpush?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

<img src="https://raw.github.com/rpush/rpush/master/logo.png" align="right" width="200px" />

### Rpush. The push notification service for Ruby.

Rpush aims to be the *de facto* gem for sending push notifications in Ruby. Its core goals are ease of use, reliability and a rich feature set. Rpush provides numerous advanced features not found in others gems, giving you greater control & insight as your project grows. These are a few of the reasons why companies worldwide rely on Rpush to deliver their notifications.

#### Supported Services

  * [**Apple Push Notification Service**](#apple-push-notification-service)
    * Including Safari Push Notifications.
  * [**Google Cloud Messaging**](#google-cloud-messaging)
  * [**Amazon Device Messaging**](#amazon-device-messaging)
  * [**Windows Phone Push Notification Service**](#windows-phone-notification-service)

#### Feature Highlights

* Use [**ActiveRecord**](https://github.com/rpush/rpush/wiki/Using-ActiveRecord), [**Redis**](https://github.com/rpush/rpush/wiki/Using-Redis) or [**MongoDB**](https://github.com/rpush/rpush/wiki/Using-Mongodb) for storage.
* Plugins for [**Bugsnag**](https://github.com/rpush/rpush-plugin-bugsnag),
[**Sentry**](https://github.com/rpush/rpush-plugin-sentry), [**StatsD**](https://github.com/rpush/rpush-plugin-statsd) or [write your own](https://github.com/rpush/rpush/wiki/Writing-a-Plugin).
* Seamless integration with your projects, including **Rails**.
* Run as a [daemon](https://github.com/rpush/rpush#as-a-daemon), inside a [job queue](https://github.com/rpush/rpush/wiki/Push-API), on the [command-line](https://github.com/rpush/rpush#on-the-command-line) or [embedded](https://github.com/rpush/rpush/wiki/Embedding-API) in another process.
* Scales vertically (threading) and horizontally (multiple processes).
* Designed for uptime - new apps are loaded automatically, signal `HUP` to update running apps.
* Hooks for fine-grained instrumentation and error handling ([Reflection API](https://github.com/rpush/rpush/wiki/Reflection-API)).
* Works with **MRI**, **JRuby** and **Rubinius**.


### Getting Started

Add it to your Gemfile:

```ruby
gem 'rpush'
```

Initialize Rpush into your project. **Rails will be detected automatically.**

```sh
$ cd /path/to/project
$ rpush init
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
n.device_token = "..." # 64-character hex string
n.alert = "hi mom!"
n.data = { foo: :bar }
n.save!
```

The `url_args` attribute is available for Safari Push Notifications.

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
n.data = {title:"MyApp", body:"Hello world", param:"user_param1"}
n.save!
```

### Running Rpush

It is recommended to run Rpush as a separate process in most cases, though embedding and manual modes are provided for low-workload environments.

See `rpush help` for all available commands and options.

#### As a daemon

```sh
$ cd /path/to/project
$ rpush start
```

#### On the command-line

```sh
$ rpush push
```

Rpush will deliver all pending notifications and then exit.

#### In a scheduled job

```ruby
Rpush.push
Rpush.apns_feedback
```

See [Push API](https://github.com/rpush/rpush/wiki/Push-API) for more details.

#### Embedded inside an existing process

```ruby
if defined?(Rails)
  ActiveSupport.on_load(:after_initialize) do
    Rpush.embed
  end
else
  Rpush.embed
end
```

Call this during startup of your application, for example, by adding it to the end of `config/rpush.rb`. See [Embedding API](https://github.com/rpush/rpush/wiki/Embedding-API) for more details.

### Configuration

See [Configuration](https://github.com/rpush/rpush/wiki/Configuration) for a list of options.

### Updating Rpush

You should run `rpush init` after upgrading Rpush to check for configuration and migration changes.

### From The Wiki

### General
* [Using Redis](https://github.com/rpush/rpush/wiki/Using-Redis)
* [Using ActiveRecord](https://github.com/rpush/rpush/wiki/Using-ActiveRecord)
* [Configuration](https://github.com/rpush/rpush/wiki/Configuration)
* [Moving from Rapns](https://github.com/rpush/rpush/wiki/Moving-from-Rapns-to-Rpush)
* [Deploying to Heroku](https://github.com/rpush/rpush/wiki/Heroku)
* [Hot App Updates](https://github.com/rpush/rpush/wiki/Hot-App-Updates)
* [Signals](https://github.com/rpush/rpush/wiki/Signals)
* [Reflection API](https://github.com/rpush/rpush/wiki/Reflection-API)
* [Push API](https://github.com/rpush/rpush/wiki/Push-API)
* [Embedding API](https://github.com/rpush/rpush/wiki/Embedding-API)
* [Writing a Plugin](https://github.com/rpush/rpush/wiki/Writing-a-Plugin)
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

When running specs, please note that the ActiveRecord adapter can be changed by setting the `ADAPTER` environment variable. For example: `ADAPTER=postgresql rake`.

Available adapters for testing are `mysql`, `mysql2` and `postgresql`.

Note that the database username is changed at runtime to be the currently logged in user's name. So if you're testing
with mysql and you're using a user named 'bob', you will need to grant a mysql user 'bob' access to the 'rpush_test'
mysql database.

To switch between ActiveRecord and Redis, set the `CLIENT` environment variable to either `active_record`, `redis` or `mongoid`.


[![Build Status](https://secure.travis-ci.org/rpush/rpush.svg?branch=master)](http://travis-ci.org/rpush/rpush)
[![Test Coverage](https://codeclimate.com/github/rpush/rpush/badges/coverage.svg)](https://codeclimate.com/github/rpush/rpush)
[![Code Climate](https://codeclimate.com/github/rpush/rpush/badges/gpa.svg)](https://codeclimate.com/github/rpush/rpush)
