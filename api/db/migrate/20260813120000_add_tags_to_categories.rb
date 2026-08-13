class AddTagsToCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :tags, :jsonb, default: [], null: false
  end
end
