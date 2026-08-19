class AddIndexForInvoiceFilteringByConnection < ActiveRecord::Migration[8.1]
  def change
    add_index :invoices, [ :connection_id, :reference_date, :paid_at ],
              name: "index_invoices_on_connection_ref_paid",
              where: "deleted_at IS NULL"
  end
end
