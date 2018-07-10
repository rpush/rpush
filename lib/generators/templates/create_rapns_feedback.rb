class CreateRapnsFeedback < ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[5.0] : ActiveRecord::Migration
  def self.up
    create_table :rapns_feedback do |t|
      t.string    :device_token,          null: false, limit: 64
      t.timestamp :failed_at,             null: false
      t.timestamps
    end

    add_index :rapns_feedback, :device_token
  end

  def self.down
    if ActiveRecord::VERSION::MAJOR >= 5 && ActiveRecord::VERSION::MINOR >= 1
      if index_name_exists?(:rapns_feedback, :index_rapns_feedback_on_device_token)
        remove_index :rapns_feedback, name: :index_rapns_feedback_on_device_token
      end
    else
      if index_name_exists?(:rapns_feedback, :index_rapns_feedback_on_device_token, true)
        remove_index :rapns_feedback, name: :index_rapns_feedback_on_device_token
      end
    end

    drop_table :rapns_feedback
  end
end
