class FixConnectionActiveIndex < ActiveRecord::Migration[8.1]
  def change
    # Remove the old index that only allows 1 active connection per address
    remove_index :connections, name: "index_connections_on_address_id_active_unique", if_exists: true

    # Add new index that allows multiple active connections per address as long as number+letter differs
    add_index :connections,
              "address_id, number, COALESCE(letter, ''::character varying), active",
              name: "index_connections_on_address_number_letter_active_unique",
              unique: true,
              where: "((active = true) AND (deleted_at IS NULL))",
              if_not_exists: true
  end
end
