class LinkCustomersToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :customer_id, :uuid
    add_column :users, :failed_login_attempts, :integer, null: false, default: 0
    add_column :users, :locked_until, :datetime
    add_index :users, :customer_id, unique: true, where: "customer_id IS NOT NULL"

    backfill_customer_users

    remove_column :customers, :failed_login_attempts
    remove_column :customers, :locked_until
  end

  def down
    add_column :customers, :failed_login_attempts, :integer, null: false, default: 0
    add_column :customers, :locked_until, :datetime

    execute <<~SQL
      UPDATE customers
      SET failed_login_attempts = users.failed_login_attempts,
          locked_until = users.locked_until
      FROM users
      WHERE users.customer_id = customers.id
    SQL

    User.where.not(customer_id: nil).delete_all
    remove_index :users, :customer_id
    remove_column :users, :customer_id
    remove_column :users, :locked_until
    remove_column :users, :failed_login_attempts
  end

  private

  # One User per existing Customer, reusing their document as username and
  # their existing customer_code as the password (bcrypt-hashed by
  # has_secure_password, same as any other User) — this is what makes the
  # unified /session login work for accounts created before this migration.
  def backfill_customer_users
    Customer.reset_column_information

    Customer.unscoped.find_each do |customer|
      user = User.new(
        name: customer.name,
        username: customer.document,
        password: customer.customer_code,
        role: "customer",
        customer_id: customer.id,
        failed_login_attempts: customer.failed_login_attempts,
        locked_until: customer.locked_until,
        deleted_at: customer.deleted_at
      )
      user.save!(validate: false)
    end
  end
end
