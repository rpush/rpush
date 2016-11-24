## 2.8.0 (unreleased)

#### Features

* Added support for APNS `mutable-content` ([#296](https://github.com/rpush/rpush/pull/296) by [@tdtran](https://github.com/tdtran))
* Added support for HTTP2 base APNS Api ([#315](https://github.com/rpush/rpush/pull/315) by [@soulfly](https://github.com/soulfly) and [@Nattfodd](https://github.com/Nattfodd)

#### Changes

* Make synchronizer aware of GCM and WNS apps ([#254](https://github.com/rpush/rpush/pull/254) by [@wouterh](https://github.com/wouterh))
* Precise after init commit msg ([#266](https://github.com/rpush/rpush/pull/266) by [@azranel](https://github.com/azranel))
* Use new GCM endpoint ([#303](https://github.com/rpush/rpush/pull/303) by [@aried3r](https://github.com/aried3r))

#### Bugfixes

* ~~~Lock `net-http-persistent` dependency to `< 3`. See also [#306](https://github.com/rpush/rpush/issues/306) for more details. (by [@amaierhofer](https://github.com/amaierhofer))~~~
* Fix `net-http-persistent` initializer to support version 2.x as well as 3.x. ([#309](https://github.com/rpush/rpush/pull/309) by [@amirmujkic](https://github.com/amirmujkic))

## 2.7.0 (February 9, 2016)

#### Features

* Added support for GCM priorities. ([#243](https://github.com/rpush/rpush/pull/243) by [@aried3r](https://github.com/aried3r))
* Added support for GCM notification payload ([#246](https://github.com/rpush/rpush/pull/246) by [@aried3r](https://github.com/aried3r))
* Added support for Windows Raw Notifications (in JSON form) ([#238](https://github.com/rpush/rpush/pull/238) by [@mseppae](https://github.com/mseppae))
* Added WNS badge notifications ([#247](https://github.com/rpush/rpush/pull/247) by [@wouterh](https://github.com/wouterh))
* Added the `launch` argument of WNS toast notifications ([#247](https://github.com/rpush/rpush/pull/247) by [@wouterh](https://github.com/wouterh))
* Added sound in WNS toast notifications ([#247](https://github.com/rpush/rpush/pull/247) by [@wouterh](https://github.com/wouterh))

#### Changes

* Change `alert` type from `string` to `text` in ActiveRecord to allow bigger alert dictionaries. ([#248](https://github.com/rpush/rpush/pull/248) by [@schmidt](https://github.com/schmidt))

#### Fixes

* Fixed issue where setting the `mdm` parameter broke `to_binary` for MDM APNs ([#234](https://github.com/rpush/rpush/pull/234) by [@troya2](https://github.com/troya2))
* Fixed `as_json` ([#231](https://github.com/rpush/rpush/issues/231) by [@aried3r](https://github.com/aried3r))

## 2.6.0 (January 25, 2016)

#### Features

* Added support for GCM for iOS' `content_available`. ([#221](https://github.com/rpush/rpush/pull/221))

#### Fixes

* Fix typo in Oracle support. ([#185](https://github.com/rpush/rpush/pull/185))
* Remove `param` tag from WNS message. ([#190](https://github.com/rpush/rpush/pull/190))
* Fixed WNS response headers parser. ([#192](https://github.com/rpush/rpush/pull/192))
* GCM: fixed raise of unhandled errors. ([#193](https://github.com/rpush/rpush/pull/193))
* Fix issue with custom PID file set in `Rpush.config`. ([#224](https://github.com/rpush/rpush/pull/224), [#225](https://github.com/rpush/rpush/pull/225))

## 2.5.0 (July 19, 2015)
  Features:
  * Add 'rpush status' to inspect running Rpush internal status.
  * ActiveRecord logging is no longer redirected to rpush.log when embedded (#138).
  * Support for WNS (Windows RT) (#137).
  * Indexes added to some Mongoid fields (#151).
  * Added support for Oracle.

  Bug fixes:
  * Fix for handling APNs error when using `rpush push` or `Rpush.push`.
  * Fix backwards compatibility issue with ActiveRecord (#144).

## 2.4.0 (Feb 18, 2015)
  Features:
  * Support for MongoDB (using Mongoid).
  * config.feedback_poll is now deprecated, use config.apns.feedback_receiver.frequency instead.
  * Add config.apns.feedback_receiver.enabled to optionally enable the APNs feedback receiver (#129).
  * Passing configuration options directly to Rpush.embed and Rpush.push is now deprecated.

  Bug fixes:
  * Fix setting the log level when using Rails 4+ or without Rails (#124).
  * Fix the possibility for excessive error logging when using APNs (#128).
  * Re-use timestamp when replacing a migration with the same name (#91).
  * Ensure App/Notification type is updated during 2.0 upgrade migration (#102).

## 2.3.2 (Jan 30, 2015)
  Bug fixes:
  * Internal sleep mechanism would sometimes no wait for the full duration specified.
  * Rpush.push nows delivers all pending notifications before returning.
  * Require thor >= 0.18.1 (#121).

## 2.3.1 (Jan 24, 2015)
  * Fix CPU thrashing while waiting for an APNs connection be established (#119).

## 2.3.0 (Jan 19, 2015)
  * Add 'version' CLI command.
  * Rpush::Wpns::Notification now supports setting the 'data' attribute.
  * ActiveRecord is now directed to the configured Rpush logger (#104).
  * Logs are reopened when the HUP signal is received (#95).
  * Fix setting config.redis_options (#114).
  * Increase frequency of TCP keepalive probes on Linux.
  * APNs notifications are no longer marked as failed when a dropped connection is detected, as it's impossible to know exactly how many actually failed (if any).
  * Notifications are now retried instead of being marked as failed if a TCP/HTTP connection cannot be established.

## 2.2.0 (Oct 7, 2014)
  * Numerous command-line fixes, sorry folks!
  * Add 'rpush push' command-line command for one-off use.

## 2.1.0 (Oct 4, 2014)
  * Bump APNs max payload size to 2048 for iOS 8.
  * Add 'category' for iOS 8.
  * Add url_args for Safari Push Notification Support (#77).
  * Improved command-line interface.
  * Rails integration is now optional.
  * Added log_level config option.
  * log_dir is now deprecated and has no effect, use log_file instead.

## 2.0.1 (Sept 13, 2014)
  * Add ssl_certificate_revoked reflection (#68).
  * Fix for Postgis support in 2.0.0 migration (#70).

## 2.0.0 (Sept 6, 2014)
  * Use APNs enhanced binary format version 2.
  * Support running multiple Rpush processes when using ActiveRecord and Redis.
  * APNs error detection is now performed asynchronously, 'check_for_errors' is therefore deprecated.
  * Deprecated attributes_for_device accessors. Use data instead.
  * Fix signal handling to work with Ruby 2.x. (#40).
  * You no longer need to signal HUP after creating a new app, they will be loaded automatically for you.
  * APNs notifications are now delivered in batches, greatly improving throughput.
  * Signaling HUP now also causes Rpush to immediately check for new notifications.
  * The 'wakeup' config option has been removed.
  * The 'batch_storage_updates' config option has been deprecated, storage backends will now always batch updates where appropriate.
  * The rpush process title updates with number of queued notifications and number of dispatchers.
  * Rpush::Apns::Feedback#app has been renamed to app_id and is now an Integer.
  * An app is restarted when the HUP signal is received if its certificate or environment attribute changed.

## 1.0.0 (Feb 9, 2014)
  * Renamed to Rpush (from Rapns). Version number reset to 1.0.0.
  * Reduce default batch size to 100.
  * Fix sqlite3 support (#160).
  * Drop support for Ruby 1.8.
  * Improve APNs certificate validation errors (#192) @mattconnolly).
  * Support for Windows Phone notifications (#191) (@matiaslina).
  * Support for Amazon device messaging (#173) (@darrylyip).
  * Add two new GCM reflections: gcm_delivered_to_recipient, gcm_failed_to_recipient (#184) (@jakeonfire).
  * Fix migration issues (#181) (@jcoleman).
  * Add GCM gcm_invalid_registration_id reflection (#171) (@marcrohloff).
  * Feature: wakeup feeder via UDP socket (#164) (@mattconnolly).
  * Fix reflections when using batches (#161).
  * Only perform APNs certificate validation for APNs apps (#133).
  * The deprecated on_apns_feedback has now been removed.
  * The deprecated airbrake_notify config option has been removed.
  * Removed the deprecated ability to set attributes_for_device using mass-assignment.
  * Fixed issue where database connections may not be released from the connection pool.

## 3.4.1 (Aug 30, 2013)
  * Silence unintended airbrake_notify deprecation warning (#158).
  * Add :dependent => :destroy to app notifications (#156).

## 3.4.0 (Aug 28, 2013)
  * Rails 4 support.
  * Add apns_certificate_will_expire reflection.
  * Perform storage update in batches where possible, to increase throughput.
  * airbrake_notify is now deprecated, use the Reflection API instead.
  * Fix calling the notification_delivered reflection twice (#149).

## 3.3.2 (June 30, 2013)
  * Fix Rails 3.0.x compatibility (#138) (@yoppi).
  * Ensure Rails does not set a default value for text columns (#137).
  * Fix error in down action for add_gcm migration (#135) (@alexperto).

## 3.3.1 (June 2, 2013)
  * Fix compatibility with postgres_ext (#104).
  * Add ability to switch the logger (@maxsz).
  * Do not validate presence of alert, badge or sound - not actually required by the APNs (#129) (@wilg).
  * Catch IOError from an APNs connection. (@maxsz).
  * Allow nested hashes in APNs notification attributes (@perezda).

## 3.3.0 (April 21, 2013)
  * GCM: collapse_key is no longer required to set expiry (time_to_live).
  * Add reflection for GCM canonical IDs.
  * Add Rpush::Daemon.store to decouple storage backend.

## 3.2.0 (Apr 1, 2013)
  * Rpush.apns_feedback for one time feedback retrieval. Rpush.push no longer checks for feedback (#117, #105).
  * Lazily connect to the APNs only when a notification is to be delivered (#111).
  * Ensure all notifications are sent when using Rpush.push (#107).
  * Fix issue with running Rpush.push more than once in the same process (#106).

## 3.1.0 (Jan 26, 2013)
  * Rpush.reflect API for fine-grained introspection.
  * Rpush.embed API for embedding Rpush into an existing process.
  * Rpush.push API for using Rpush in scheduled jobs.
  * Fix issue with integration with ActiveScaffold (#98) (@jeffarena).
  * Fix content-available setter for APNs (#95) (@dup2).
  * GCM validation fixes (#96) (@DianthuDia).

## 3.0.1 (Dec 16, 2012)
  * Fix compatibility with Rails 3.0.x. Fixes #89.

## 3.0.0 (Dec 15, 2012)
  * Add support for Google Cloud Messaging.
  * Fix Heroku logging issue.

##  2.0.5 (Nov 4, 2012) ##
  * Support content-available (#68).
  * Append to log files.
  * Fire a callback when Feedback is received.

## 2.0.5.rc1 (Oct 5, 2012) ##
  * Release db connections back into the pool after use (#72).
  * Continue to start daemon if a connection cannot be made during startup (#62) (@mattconnolly).

## 2.0.4 (Aug 6, 2012) ##
  * Don't exit when there aren't any Rpush::App instances, just warn (#55).

## 2.0.3 (July 26, 2012) ##
  * JRuby support.
  * Explicitly list all attributes instead of calling column_names (#53).

## 2.0.2 (July 25, 2012) ##
  * Support MultiJson < 1.3.0.
  * Make all model attributes accessible.

## 2.0.1 (July 7, 2012) ##
  * Fix delivery when using Ruby 1.8.
  * MultiJson support.

## 2.0.0 (June 19, 2012) ##

  * Support for multiple apps.
  * Hot Updates - add/remove apps without restart.
  * MDM support.
  * Removed rpush.yml in favour of command line options.
  * Started the changelog!
