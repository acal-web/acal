class OptimizeCustomerSearchIndexes < ActiveRecord::Migration[7.0]
  def change
    # Add indexes for case-insensitive searches on name
    add_index :customers, "LOWER(name) varchar_pattern_ops",
              using: :btree,
              name: 'index_customers_name_lower',
              if_not_exists: true

    # Add indexes for case-insensitive searches on document
    add_index :customers, "LOWER(document) varchar_pattern_ops",
              using: :btree,
              name: 'index_customers_document_lower',
              if_not_exists: true

    # Add indexes for sorting operations
    add_index :customers, :membership_number, if_not_exists: true
    add_index :customers, :voter, if_not_exists: true
  end
end
