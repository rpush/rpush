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
          ids = notifications.map(&:id)
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
          ids = notifications.map(&:id)
          with_database_reconnect_and_retry do
            Rapns::Notification.where(:id => ids).update_all(['delivered = true, delivered_at = ?', Time.now])
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
          ids = notifications.map(&:id)
          with_database_reconnect_and_retry do
            Rapns::Notification.where(:id => ids).update_all(['delivered = false, delivered_at = NULL, failed = true, failed_at = ?, error_code = ?, error_description = ?', Time.now, code, description])
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

        def after_daemonize
          reconnect_database
        end
      end
    end
  end
end
