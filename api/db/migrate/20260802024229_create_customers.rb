class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers, id: :uuid do |t|
      t.string :name
      t.string :document
      t.integer :membership_number
      t.boolean :voter, null: false, default: false
      t.integer :legacy_id
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :customers, :document
  end
end
