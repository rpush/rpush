class RenameRapnsToRpush < ActiveRecord::Migration
  module Rpush
    class Notification < ActiveRecord::Base
      self.table_name = 'rpush_notifications'
    end
  end

  def self.up
    rename_table :rapns_notifications, :rpush_notifications
    rename_table :rapns_apps, :rpush_apps
    rename_table :rapns_feedback, :rpush_feedback

    rename_index :rpush_notifications, :index_rapns_notifications_multi, :index_rpush_notifications_multi
    rename_index :rpush_feedback, :index_rapns_feedback_on_device_token, :index_rpush_feedback_on_device_token

    RenameRapnsToRpush::Rpush::Notification.where(type: 'Rapns::Apns::Notification').update_all(type: 'Rpush::Apns::Notification')
    RenameRapnsToRpush::Rpush::Notification.where(type: 'Rapns::Gcm::Notification').update_all(type: 'Rpush::Gcm::Notification')
    RenameRapnsToRpush::Rpush::Notification.where(type: 'Rapns::Adm::Notification').update_all(type: 'Rpush::Adm::Notification')
    RenameRapnsToRpush::Rpush::Notification.where(type: 'Rapns::Wpns::Notification').update_all(type: 'Rpush::Wpns::Notification')
  end

  def self.down
    RenameRapnsToRpush::Rpush::Notification.where(type: 'Rpush::Apns::Notification').update_all(type: 'Rapns::Apns::Notification')
    RenameRapnsToRpush::Rpush::Notification.where(type: 'Rpush::Gcm::Notification').update_all(type: 'Rapns::Gcm::Notification')
    RenameRapnsToRpush::Rpush::Notification.where(type: 'Rpush::Adm::Notification').update_all(type: 'Rapns::Adm::Notification')
    RenameRapnsToRpush::Rpush::Notification.where(type: 'Rpush::Wpns::Notification').update_all(type: 'Rapns::Wpns::Notification')

    rename_index :rpush_notifications, :index_rpush_notifications_multi, :index_rapns_notifications_multi
    rename_index :rpush_feedback, :index_rpush_feedback_on_device_token, :index_rapns_feedback_on_device_token

    rename_table :rpush_notifications, :rapns_notifications
    rename_table :rpush_apps, :rapns_apps
    rename_table :rpush_feedback, :rapns_feedback
  end
end
