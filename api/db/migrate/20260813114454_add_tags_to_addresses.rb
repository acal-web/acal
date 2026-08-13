class AddTagsToAddresses < ActiveRecord::Migration[8.1]
  def change
    add_column :addresses, :tags, :jsonb, default: [], null: false
  end
end
