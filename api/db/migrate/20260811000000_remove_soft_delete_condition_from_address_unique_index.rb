class RemoveSoftDeleteConditionFromAddressUniqueIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :addresses, name: "index_addresses_on_kind_and_name_unique"

    add_index :addresses, [ :kind, :name ],
      unique: true,
      name: "index_addresses_on_kind_and_name_unique"
  end
end
