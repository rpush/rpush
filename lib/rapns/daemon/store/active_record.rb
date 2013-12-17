require 'active_record'

require 'rapns/daemon/store/active_record/reconnectable'

module Rapns
  module Daemon
    module Store
      class ActiveRecord
        include Reconnectable

        def deliverable_notifications(apps)
          with_database_reconnect_and_retry do
            batch_size = Rapns.config.batch_size
            relation = Rapns::Notification.ready_for_delivery.for_apps(apps)
            relation = relation.limit(batch_size) unless Rapns.config.push
            relation.to_a
          end
        end

        def mark_retryable(notification, deliver_after)
          with_database_reconnect_and_retry do
            notification.retries += 1
            notification.deliver_after = deliver_after
            notification.save!(:validate => false)
          end
        end

        def mark_batch_retryable(notifications, deliver_after)
          ids = []
          notifications.each do |n|
            # Update attrs for reflections, but don't save.
            n.retries += 1
            n.deliver_after = deliver_after
            ids << n.id
          end
          with_database_reconnect_and_retry do
            Rapns::Notification.where(:id => ids).update_all(['retries = retries + 1, deliver_after = ?', deliver_after])
          end
        end

        def mark_delivered(notification)
          with_database_reconnect_and_retry do
            notification.delivered = true
            notification.delivered_at = Time.now
            notification.save!(:validate => false)
          end
        end

        def mark_batch_delivered(notifications)
          now = Time.now
          ids = []
          notifications.each do |n|
            # Update attrs for reflections, but don't save.
            n.delivered = true
            n.delivered_at = now
            ids << n.id
          end
          with_database_reconnect_and_retry do
            Rapns::Notification.where(:id => ids).update_all(['delivered = ?, delivered_at = ?', true, now])
          end
        end

        def mark_failed(notification, code, description)
          with_database_reconnect_and_retry do
            notification.delivered = false
            notification.delivered_at = nil
            notification.failed = true
            notification.failed_at = Time.now
            notification.error_code = code
            notification.error_description = description
            notification.save!(:validate => false)
          end
        end

        def mark_batch_failed(notifications, code, description)
          now = Time.now
          ids = []
          notifications.each do |n|
            # Update attrs for reflections, but don't save.
            n.delivered = false
            n.delivered_at = nil
            n.failed = true
            n.failed_at = now
            n.error_code = code
            n.error_description = description
            ids << n.id
          end
          with_database_reconnect_and_retry do
            Rapns::Notification.where(:id => ids).update_all(['delivered = ?, delivered_at = NULL, failed = ?, failed_at = ?, error_code = ?, error_description = ?', false, true, now, code, description])
          end
        end

        def create_apns_feedback(failed_at, device_token, app)
          with_database_reconnect_and_retry do
            Rapns::Apns::Feedback.create!(:failed_at => failed_at,
              :device_token => device_token, :app => app)
          end
        end

        def create_gcm_notification(attrs, data, registration_ids, deliver_after, app)
          with_database_reconnect_and_retry do
            notification = Rapns::Gcm::Notification.new
            notification.assign_attributes(attrs)
            notification.data = data
            notification.registration_ids = registration_ids
            notification.deliver_after = deliver_after
            notification.app = app
            notification.save!
            notification
          end
        end

        def create_wpns_notification(attrs,data,uri, app)
          with_database_reconnect_and_retry do
            notification = Rapns::Wpns::Notification.new
            notification.assign_attributes(attrs)
            notification.data = data
            notification.uri = uri
            notification.app = app
            notification.save!
            notification
          end
        end

        def after_daemonize
          reconnect_database
        end
      end
    end
  end
end
