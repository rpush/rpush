require 'rpush/daemon/store/active_record'

# The default AR implementation throws an error when trying to lock resources
# when using an ORDER clause with FOR UPDATE. Instead of ORDER in SQL, we
# simply sort the result set in memory.
module Rpush
  module Daemon
    module Store
      class Oracle < Rpush::Daemon::Store::ActiveRecord
        def deliverable_notifications(limit)
          with_database_reconnect_and_retry do
            Rpush::Client::ActiveRecord::Notification.transaction do
              relation = ready_for_delivery
              relation = relation.limit(limit)
              notifications = relation.lock(true).to_a.sort_by(&:created_at)
              mark_processing(notifications)
              notifications
            end
          end
        end

        private

        def ready_for_delivery
          Rpush::Client::ActiveRecord::Notification.where('processing = ? AND delivered = ? AND failed = ? AND (deliver_after IS NULL OR deliver_after < ?)', false, false, false, Time.now)
        end
      end
    end
  end
