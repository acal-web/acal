class AddLegacyIdToQualityAnalyses < ActiveRecord::Migration[8.1]
  def change
    add_column :quality_analyses, :legacy_id, :integer
    add_index :quality_analyses, :legacy_id, unique: true
  end
end
