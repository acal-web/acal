class CreateConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :connections, id: :uuid do |t|
      t.references :customer, type: :uuid, null: false, foreign_key: true
      t.references :address, type: :uuid, null: false, foreign_key: true
      t.references :category, type: :uuid, null: false, foreign_key: true
      t.boolean :active, null: false, default: true
      t.integer :legacy_id
      t.datetime :deleted_at

      t.timestamps
    end

    # An address may have only one ACTIVE connection at a time. Ended
    # (active: false) and soft-deleted connections are excluded, so history
    # is preserved and a new connection can be opened once the old one is
    # ended — mirrors the soft-delete-aware unique index style used for
    # addresses/categories.
    add_index :connections, :address_id,
      unique: true,
      where: "active = true AND deleted_at IS NULL",
      name: "index_connections_on_address_id_active_unique"
  end
end
