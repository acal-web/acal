class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices, id: :uuid do |t|
      t.references :connection, null: false, type: :uuid, foreign_key: true
      t.date :reference_date, null: false
      t.date :due_date, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    # Only one invoice per connection per reference month, ignoring soft-deleted rows.
    add_index :invoices, [ :connection_id, :reference_date ],
      unique: true,
      where: "deleted_at IS NULL",
      name: "index_invoices_on_connection_id_and_reference_date_unique"
  end
end
