class MakeAddressesKindNameIndexCaseInsensitive < ActiveRecord::Migration[8.1]
  def up
    remove_index :addresses, name: "index_addresses_on_kind_and_name_unique"
    add_index :addresses, "lower(kind), lower(name)",
      unique: true,
      where: "deleted_at IS NULL",
      name: "index_addresses_on_kind_and_name_unique"
  end

  def down
    remove_index :addresses, name: "index_addresses_on_kind_and_name_unique"
    add_index :addresses, [ :kind, :name ],
      unique: true,
      where: "deleted_at IS NULL",
      name: "index_addresses_on_kind_and_name_unique"
  end
end
