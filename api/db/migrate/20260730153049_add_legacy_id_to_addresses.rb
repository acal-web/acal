class AddLegacyIdToAddresses < ActiveRecord::Migration[8.1]
  def change
    add_column :addresses, :legacy_id, :integer
  end
end
