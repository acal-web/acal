class CreateWaterMeters < ActiveRecord::Migration[8.1]
  def change
    create_table :water_meters, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :invoice, null: false, foreign_key: true, type: :uuid
      t.date :measured_at, null: false
      t.decimal :initial_reading, precision: 10, scale: 2, null: false
      t.decimal :final_reading, precision: 10, scale: 2, null: false
      t.integer :legacy_id
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :water_meters, :legacy_id, unique: true
    add_index :water_meters, [ :invoice_id, :measured_at ], unique: true, where: "(deleted_at IS NULL)"
  end
end
