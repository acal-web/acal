class AddTagsToCustomers < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :tags, :jsonb, default: [], null: false
  end
end
