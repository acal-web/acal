class AddNumberToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :number, :string
    add_index :invoices, :number, unique: true
  end
end
