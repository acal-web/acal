class AddTagsToConnections < ActiveRecord::Migration[8.1]
  def change
    add_column :connections, :tags, :jsonb, default: [], null: false
  end
end
