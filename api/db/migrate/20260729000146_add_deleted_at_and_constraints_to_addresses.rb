class AddDeletedAtAndConstraintsToAddresses < ActiveRecord::Migration[8.1]
  def change
    add_column :addresses, :deleted_at, :datetime
    add_index :addresses, :name
    # Scoped to deleted_at IS NULL so a soft-deleted address doesn't block
    # re-creating the same type+name combination.
    add_index :addresses, [ :address_type, :name ], unique: true, where: "deleted_at IS NULL", name: "index_addresses_on_address_type_and_name_unique"
  end
end
