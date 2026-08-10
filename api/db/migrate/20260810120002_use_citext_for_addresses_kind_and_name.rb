class UseCitextForAddressesKindAndName < ActiveRecord::Migration[8.1]
  def change
    enable_extension 'citext'

    # Remove the old index since citext doesn't need COLLATE
    remove_index :addresses, name: "index_addresses_on_kind_and_name_unique"

    change_column :addresses, :kind, :citext
    change_column :addresses, :name, :citext

    # Re-add the index on citext columns (case-insensitive by default)
    add_index :addresses, [ :kind, :name ],
      unique: true,
      where: "deleted_at IS NULL",
      name: "index_addresses_on_kind_and_name_unique"
  end
end
