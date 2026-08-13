class SplitInvoiceAmountIntoMembershipAndWaterValue < ActiveRecord::Migration[8.1]
  def up
    add_column :invoices, :membership_value, :decimal, precision: 10, scale: 2
    add_column :invoices, :water_value, :decimal, precision: 10, scale: 2

    execute "UPDATE invoices SET membership_value = amount, water_value = 0"

    change_column_null :invoices, :membership_value, false
    change_column_null :invoices, :water_value, false
    change_column_default :invoices, :membership_value, 0
    change_column_default :invoices, :water_value, 0

    remove_column :invoices, :amount
  end

  def down
    add_column :invoices, :amount, :decimal, precision: 10, scale: 2
    execute "UPDATE invoices SET amount = membership_value + water_value"
    change_column_null :invoices, :amount, false

    remove_column :invoices, :membership_value
    remove_column :invoices, :water_value
  end
end
