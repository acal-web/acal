class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications, id: :uuid do |t|
      t.string :title, null: false
      t.string :body, null: false
      t.uuid :address_id
      t.uuid :category_id
      t.string :status
      t.integer :recipient_count, null: false, default: 0
      t.uuid :sent_by_id, null: false

      t.timestamps
    end

    add_index :notifications, :address_id
    add_index :notifications, :category_id
    add_index :notifications, :sent_by_id
  end
end
