class AddNumberAndLetterToConnections < ActiveRecord::Migration[8.1]
  def up
    add_column :connections, :number, :integer
    add_column :connections, :letter, :string

    # Backfill any pre-existing rows with a per-address sequence so the
    # NOT NULL constraint below can be added safely.
    execute <<~SQL
      UPDATE connections SET number = seq.n
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY address_id ORDER BY created_at) AS n
        FROM connections
      ) AS seq
      WHERE connections.id = seq.id
    SQL

    change_column_null :connections, :number, false

    # A (address, number) pair can repeat only if `letter` differs — coalesce
    # letter to '' so two rows with no letter collide as duplicates (Postgres
    # treats NULL <> NULL, which would otherwise let unlimited duplicates
    # through). Soft-deleted connections don't participate.
    add_index :connections, "address_id, number, coalesce(letter, '')",
      unique: true,
      where: "deleted_at IS NULL",
      name: "index_connections_on_address_id_number_letter_unique"
  end

  def down
    remove_index :connections, name: "index_connections_on_address_id_number_letter_unique"
    remove_column :connections, :letter
    remove_column :connections, :number
  end
end
