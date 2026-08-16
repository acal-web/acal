class AddWaterConsumedValueToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :water_consumed_value, :decimal
  end
end
