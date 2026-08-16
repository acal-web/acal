class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.citext :username, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :role, null: false
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :users, :username, unique: true, where: "deleted_at IS NULL"
  end
end
