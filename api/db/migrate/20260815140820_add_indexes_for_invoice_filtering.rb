class AddIndexesForInvoiceFiltering < ActiveRecord::Migration[8.1]
  def change
    add_index :invoices, :paid_at, where: "deleted_at IS NULL"
    add_index :invoices, :due_date, where: "deleted_at IS NULL"
    add_index :invoices, [ :reference_date, :paid_at ], where: "deleted_at IS NULL"
    add_index :invoices, [ :due_date, :paid_at ], where: "deleted_at IS NULL"
  end
end
