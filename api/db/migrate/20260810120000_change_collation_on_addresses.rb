class ChangeCollationOnAddresses < ActiveRecord::Migration[8.1]
  def change
    execute 'ALTER TABLE addresses ALTER COLUMN kind TYPE varchar COLLATE "en_US.utf8"'
    execute 'ALTER TABLE addresses ALTER COLUMN name TYPE varchar COLLATE "en_US.utf8"'
  end
end
