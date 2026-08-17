class DropSessionsTable < ActiveRecord::Migration[8.1]
  def change
    drop_table :sessions, if_exists: true
  end
end
