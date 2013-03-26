## 3.2.0 (not released)
  * Rapns.apns_feedback for one time feedback retrieval. Rapns.push no longer checks for feedback.

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
