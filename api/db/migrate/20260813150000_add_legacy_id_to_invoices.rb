class AddLegacyIdToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :legacy_id, :integer
    add_index :invoices, :legacy_id, unique: true
  end
end
