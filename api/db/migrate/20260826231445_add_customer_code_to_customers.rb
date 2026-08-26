class AddCustomerCodeToCustomers < ActiveRecord::Migration[8.1]
  def up
    add_column :customers, :customer_code, :string, limit: 10
    add_column :customers, :failed_login_attempts, :integer, null: false, default: 0
    add_column :customers, :locked_until, :datetime

    backfill_customer_codes

    add_index :customers, :customer_code, unique: true
  end

  def down
    remove_index :customers, :customer_code
    remove_column :customers, :locked_until
    remove_column :customers, :failed_login_attempts
    remove_column :customers, :customer_code
  end

  private

  # Assigns a unique 6-digit code to every existing customer. Runs before the
  # unique index is added, so collisions are checked in Ruby against what's
  # been assigned so far in this run plus what's already on disk.
  def backfill_customer_codes
    used_codes = execute("SELECT customer_code FROM customers WHERE customer_code IS NOT NULL").map { |row| row["customer_code"] }.to_set

    execute("SELECT id FROM customers WHERE customer_code IS NULL").each do |row|
      code = generate_unique_code(used_codes)
      used_codes << code
      execute("UPDATE customers SET customer_code = #{quote(code)} WHERE id = #{quote(row["id"])}")
    end
  end

  def generate_unique_code(used_codes)
    loop do
      code = format("%06d", rand(1_000_000))
      break code unless used_codes.include?(code)
    end
  end
end
