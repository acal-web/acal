class AddUniqueIndexOnDocumentToCustomers < ActiveRecord::Migration[8.1]
  def change
    remove_index :customers, :document
    add_index :customers, :document, unique: true
  end
end
