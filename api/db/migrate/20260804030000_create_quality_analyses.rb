class CreateQualityAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :quality_analyses, id: :uuid do |t|
      t.date :reference_date, null: false
      t.string :param_name, null: false
      t.integer :required, null: false
      t.integer :analyzed, null: false
      t.integer :compliant, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    # Only one entry per parameter per reference month, ignoring soft-deleted rows.
    add_index :quality_analyses, [ :reference_date, :param_name ],
      unique: true,
      where: "deleted_at IS NULL",
      name: "index_quality_analyses_on_reference_date_and_param_name_unique"
  end
end
