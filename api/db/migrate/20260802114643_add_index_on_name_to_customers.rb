class AddIndexOnNameToCustomers < ActiveRecord::Migration[8.1]
  def change
    add_index :customers, :name
  end
end
