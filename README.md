[![Build Status](https://secure.travis-ci.org/ileitch/rapns.png?branch=master)](http://travis-ci.org/ileitch/rapns)

### Rapns - Professional grade APNs and GCM for Ruby.

* Supports both APNs (iOS) and GCM (Google Cloud Messaging, Android).
* Seamless Rails integration.
* Scalable - choose the number of threads each app spawns.
* Designed for uptime - signal -HUP to add, update apps.
* Stable - reconnects database and network connections when lost.
* Run as a daemon or inside an existing process.
* Use in a scheduler for low-workload deployments ([Push API](https://github.com/ileitch/rapns/wiki/Push-API)).
* Reflection API for fine-grained instrumentation ([Reflection API](https://github.com/ileitch/rapns/wiki/Relfection-API)).
* Works with MRI, JRuby, Rubinius 1.8 and 1.9.
* [Airbrake](http://airbrakeapp.com/) integration.
* Built with love.

#### 2.x users please read [upgrading from 2.x to 3.0](https://github.com/ileitch/rapns/wiki/Upgrading-from-version-2.x-to-3.0)

### Who uses Rapns?

[GateGuru](http://gateguruapp.com) and [Desk.com](http://desk.com), among others!

*I'd love to hear if you use Rapns - @ileitch on twitter.*

## Getting Started

Add Rapns to your Gemfile:

    gem 'rapns'

Generate the migrations, rapns.yml and migrate:

    rails g rapns
    rake db:migrate

## Generating Certificates (APNs only)

1. Open up Keychain Access and select the `Certificates` category in the sidebar.
2. Expand the disclosure arrow next to the iOS Push Services certificate you want to export.
3. Select both the certificate and private key.
4. Right click and select `Export 2 items...`.
5. Save the file as `cert.p12`, make sure the File Format is `Personal Information Exchange (p12)`.
6. Convert the certificate to a .pem, where `<environment>` should be `development` or `production`, depending on the certificate you exported.

Without a password:

    `openssl pkcs12 -nodes -clcerts -in cert.p12 -out <environment>.pem`

With a password:

    `openssl pkcs12 -clcerts -in cert.p12 -out <environment>.pem`

## Create an App

#### APNs
```ruby
app = Rapns::Apns::App.new
app.name = "ios_app"
app.certificate = File.read("/path/to/development.pem")
app.environment = "development"
app.password = "certificate password"
app.connections = 1
app.save!
```

#### GCM
```ruby
app = Rapns::Gcm::App.new
app.name = "android_app"
app.auth_key = "..."
app.connections = 1
app.save!
```

## Create a Notification

#### APNs
```ruby
n = Rapns::Apns::Notification.new
n.app = Rapns::Apns::App.find_by_name("ios_app")
n.device_token = "..."
n.alert = "hi mom!"
n.attributes_for_device = {:foo => :bar}
n.save!
```

#### GCM
```ruby
n = Rapns::Gcm::Notification.new
n.app = Rapns::Gcm::App.find_by_name("android_app")
n.registration_ids = ["..."]
n.data = {:message => "hi mom!"}
n.save!
```

## Starting Rapns

As a daemon:

    cd /path/to/rails/app
    rapns <Rails environment> [options]

Inside an existing process (see [Embedding API](https://github.com/ileitch/rapns/wiki/Embedding-API)):

    Rapns.embed

*Please note that only ever a single instance of Rapns should be running.*

In a scheduler:

    Rapns.push

See [Configuration](https://github.com/ileitch/rapns/wiki/Configuration) for a list of options, or run `rapns --help`.

## Updating Rapns

After updating you should run `rails g rapns` to check for any new migrations.

## Wiki

### General
* [Configuration](https://github.com/ileitch/rapns/wiki/Configuration)
* [Upgrading from 2.x to 3.0](https://github.com/ileitch/rapns/wiki/Upgrading-from-version-2.x-to-3.0)
* [Deploying to Heroku](https://github.com/ileitch/rapns/wiki/Heroku)
* [Hot App Updates](https://github.com/ileitch/rapns/wiki/Hot-App-Updates)
* [Signals](https://github.com/ileitch/rapns/wiki/Signals)
* [Reflection API](https://github.com/ileitch/rapns/wiki/Reflection-API)
* [Push API](https://github.com/ileitch/rapns/wiki/Push-API)
* [Embedding API](https://github.com/ileitch/rapns/wiki/Embedding-API)

### APNs
* [Advanced APNs Features](https://github.com/ileitch/rapns/wiki/Advanced-APNs-Features)
* [APNs Delivery Failure Handling](https://github.com/ileitch/rapns/wiki/APNs-Delivery-Failure-Handling)
* [Why open multiple connections to the APNs?](https://github.com/ileitch/rapns/wiki/Why-open-multiple-connections-to-the-APNs%3F)
* [Silent failures might be dropped connections](https://github.com/ileitch/rapns/wiki/Dropped-connections)

### GCM

## Contributing

Fork as usual and go crazy!

When running specs, please note that the ActiveRecord adapter can be changed by setting the `ADAPTER` environment variable. For example: `ADAPTER=postgresql rake`.

Available adapters for testing are `mysql`, `mysql2` and `postgresql`.

Note that the database username is changed at runtime to be the currently logged in user's name. So if you're testing
with mysql and you're using a user named 'bob', you will need to grant a mysql user 'bob' access to the 'rapns_test'
mysql database.

### Contributors

Thank you to the following wonderful people for contributing:

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
* [@jeffarena](https://github.com/jeffarena)
* [@DianthuDia](https://github.com/DianthuDia)
* [@dup2](https://github.com/dup2)
