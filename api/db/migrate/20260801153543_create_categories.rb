class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories, id: :uuid do |t|
      t.string :name
      t.text :description
      t.string :group
      t.boolean :has_water_meter, null: false, default: false
      t.decimal :water_price, precision: 10, scale: 2
      t.decimal :membership_price, precision: 10, scale: 2
      t.integer :legacy_id
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :categories, :name
    # A category name can repeat across groups, but must be unique within
    # the same group. Case-insensitive and scoped to deleted_at IS NULL so a
    # soft-deleted category doesn't block re-creating the same group+name.
    add_index :categories, 'lower("group"), lower(name)',
      unique: true,
      where: "deleted_at IS NULL",
      name: "index_categories_on_group_and_name_unique"
  end
end
