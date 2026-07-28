class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses, id: :uuid do |t|
      t.string :name
      t.string :address_type

      t.timestamps
    end
  end
end
