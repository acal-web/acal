class CreateDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :devices, id: :uuid do |t|
      t.string :owner_type, null: false
      t.uuid :owner_id, null: false
      t.string :platform, null: false
      t.string :push_token
      t.string :device_model
      t.string :os_version
      t.string :app_version
      t.datetime :last_seen_at, null: false

      t.timestamps
    end

    add_index :devices, [ :owner_type, :owner_id ]
    add_index :devices, :push_token, unique: true
  end
end
