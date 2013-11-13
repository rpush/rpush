## 3.5.0 (unreleased)
  * Fix sqlite3 support (#160).
  * Drop support for Ruby 1.8.

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
  * Add Rapns::Daemon.store to decouple storage backend.

## 3.2.0 (Apr 1, 2013)
  * Rapns.apns_feedback for one time feedback retrieval. Rapns.push no longer checks for feedback (#117, #105).
  * Lazily connect to the APNs only when a notification is to be delivered (#111).
  * Ensure all notifications are sent when using Rapns.push (#107).
  * Fix issue with running Rapns.push more than once in the same process (#106).

## 3.1.0 (Jan 26, 2013)
  * Rapns.reflect API for fine-grained introspection.
  * Rapns.embed API for embedding Rapns into an existing process.
  * Rapns.push API for using Rapns in scheduled jobs.
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
  * Don't exit when there aren't any Rapns::App instances, just warn (#55).

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
  * Removed rapns.yml in favour of command line options.
  * Started the changelog!
