class AddUserAndTimestampsToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :user_id, :uuid, null: true
    add_column :invoices, :last_updated_at, :datetime, null: true

    add_foreign_key :invoices, :users, column: :user_id, on_delete: :nullify
    add_index :invoices, :user_id
  end
end
