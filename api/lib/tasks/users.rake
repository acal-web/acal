namespace :users do
  desc "Create an initial admin user (idempotent)"
  task create_admin: :environment do
    if User.count.zero?
      admin_username = ENV.fetch("ACAL_ADMIN_USERNAME", "admin")
      admin_password = ENV.fetch("ACAL_ADMIN_PASSWORD") { SecureRandom.hex(8).tap { |p| puts "Generated admin password: #{p}" } }

      User.create!(
        username: admin_username,
        name: "Administrador",
        password: admin_password,
        role: "administrador"
      )
      puts "Created admin user: #{admin_username}"
    else
      puts "Users already exist, skipping admin creation."
    end
  end
end
