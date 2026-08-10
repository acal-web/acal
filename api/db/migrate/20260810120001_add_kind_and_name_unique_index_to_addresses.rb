class AddKindAndNameUniqueIndexToAddresses < ActiveRecord::Migration[8.1]
  def change
    add_index :addresses, [ :kind, :name ],
      unique: true,
      where: "deleted_at IS NULL",
      name: "index_addresses_on_kind_and_name_unique"
  end
end
