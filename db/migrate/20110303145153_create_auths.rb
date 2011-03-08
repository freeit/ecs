class CreateAuths < ActiveRecord::Migration
  def self.up
    create_table :auths do |t|
      t.string :one_touch_hash
      t.integer :message_id

      t.timestamps
    end
  end

  def self.down
    drop_table :auths
  end
end
