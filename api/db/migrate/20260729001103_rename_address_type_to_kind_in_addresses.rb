class RenameAddressTypeToKindInAddresses < ActiveRecord::Migration[8.1]
  def change
    rename_column :addresses, :address_type, :kind
    rename_index :addresses, "index_addresses_on_address_type_and_name_unique", "index_addresses_on_kind_and_name_unique"
  end
end
