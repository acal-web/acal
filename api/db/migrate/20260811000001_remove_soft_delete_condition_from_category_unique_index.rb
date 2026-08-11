class RemoveSoftDeleteConditionFromCategoryUniqueIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :categories, name: "index_categories_on_group_and_name_unique"

    add_index :categories, 'lower("group"), lower(name)',
      unique: true,
      name: "index_categories_on_group_and_name_unique"
  end
end
