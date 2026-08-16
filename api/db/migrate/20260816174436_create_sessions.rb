class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :last_used_at
      t.string :user_agent
      t.string :ip_address
      t.timestamps
    end
    add_index :sessions, :token_digest, unique: true
  end
end
