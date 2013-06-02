 # Rapns configuration. Options set here are overridden by command-line options.

 Rapns.configure do |config|

  # Run in the foreground?
  # config.foreground = false

  # Frequency in seconds to check for new notifications.
  # config.push_poll = 2

  # Frequency in seconds to check for feedback
  # config.feedback_poll = 60

  # Enable/Disable error notifications via Airbrake.
  # config.airbrake_notify = true

  # Disable APNs error checking after notification delivery.
  # config.check_for_errors = true

  # ActiveRecord notifications batch size.
  # config.batch_size = 5000

  # Path to write PID file. Relative to Rails root unless absolute.
  # config.pid_file = '/path/to/rapns.pid'

  # Define a custom logger.
  # config.logger = MyLogger.new

 end

Rapns.reflect do |on|

  # Called with a Rapns::Apns::Feedback instance when feedback is received
  # from the APNs that a notification has failed to be delivered.
  # Further notifications should not be sent to the device.
  # on.apns_feedback do |feedback|
  # end

  # Called when a notification is queued internally for delivery.
  # The internal queue for each app runner can be inspected:
  #
  # Rapns::Daemon::AppRunner.runners.each do |app_id, runner|
  #   runner.app
  #   runner.queue_size
  # end
  #
  # on.notification_enqueued do |notification|
  # end

  # Called when a notification is successfully delivered.
  # on.notification_delivered do |notification|
  # end

  # Called when notification delivery failed.
  # Call 'error_code' and 'error_description' on the notification for the cause.
  # on.notification_failed do |notification|
  # end

  # Called when a notification will be retried at a later date.
  # Call 'deliver_after' on the notification for the next delivery date
  # and 'retries' for the number of times this notification has been retried.
  # on.notification_will_retry do |notification|
  # end

  # Called when an APNs connection is lost and will be reconnected.
  # on.apns_connection_lost do |app, error|
  # end

  # Called when the GCM returns a canonical registration ID.
  # You will need to replace old_id with canonical_id in your records.
  # on.gcm_canonical_id do |old_id, canonical_id|
  # end

  # Called when an exception is raised.
  # on.error do |error|
  # end

end
