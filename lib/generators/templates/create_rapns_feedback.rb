class CreateRapnsFeedback < ActiveRecord::Migration
  def self.up
    create_table :rapns_feedback do |t|
      t.string    :device_token,          :null => false, :limit => 64
      t.timestamp :failed_at,             :null => false
      t.timestamps
    end

    add_index :rapns_feedback, :device_token
  end

  def self.down
    drop_table :rapns_feedback
  end
end
