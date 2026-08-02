class AddMembershipFieldsToConnections < ActiveRecord::Migration[8.1]
  def change
    add_column :connections, :membership_date, :date
    add_column :connections, :exclusively_member, :boolean, default: false, null: false
  end
end
