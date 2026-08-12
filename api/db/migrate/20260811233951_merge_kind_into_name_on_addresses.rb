class MergeKindIntoNameOnAddresses < ActiveRecord::Migration[8.1]
  def up
    # Merge kind into name: "Rua" + "das Flores" -> "Rua das Flores"
    execute "UPDATE addresses SET name = kind || ' ' || name"

    # Remove the old compound unique index
    remove_index :addresses, name: "index_addresses_on_kind_and_name_unique"

    # Remove the old redundant name-only index (will be recreated as unique)
    remove_index :addresses, name: "index_addresses_on_name"

    # Remove the kind column
    remove_column :addresses, :kind

    # Add new unique index on name alone
    add_index :addresses, :name, unique: true, name: "index_addresses_on_name_unique"
  end

  def down
    # Recreate the kind column and restore old indexes
    add_column :addresses, :kind, :citext

    # Remove the new unique name index
    remove_index :addresses, name: "index_addresses_on_name_unique"

    # Recreate old indexes (but note: cannot safely undo the text merge)
    add_index :addresses, [ :kind, :name ], unique: true, name: "index_addresses_on_kind_and_name_unique", where: "deleted_at IS NULL"
    add_index :addresses, :name, name: "index_addresses_on_name"

    raise NotImplementedError, "Downgrade is not safe: the merge of kind into name cannot be reversed. Manual data restoration required."
  end
end
