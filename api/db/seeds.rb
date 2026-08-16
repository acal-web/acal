# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create initial admin user if none exists
if User.count.zero?
  admin_username = ENV.fetch("ACAL_ADMIN_USERNAME", "admin")
  admin_password = ENV.fetch("ACAL_ADMIN_PASSWORD") { SecureRandom.hex(8).tap { |p| puts "\n[ACAL] Generated admin password: #{p}\n" } }

  User.create!(
    username: admin_username,
    name: "Administrador",
    password: admin_password,
    role: "administrador"
  )
  puts "[ACAL] Created initial admin user: #{admin_username}"
end
