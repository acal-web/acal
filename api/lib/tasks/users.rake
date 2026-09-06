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

  # The E2E suite (app/integration_test) needs one known admin to obtain its
  # first token: `POST /test/reset` truncates the users table — that admin
  # included — and the suite recreates it over the API right afterwards.
  #
  # create_admin above can't be used for this. It bails out whenever the table
  # is non-empty, and `db:prepare` on a fresh database runs db/seeds.rb first,
  # which already puts a user there. This one keys on the username instead, so
  # it lands the same admin either way.
  desc "Create or reset the admin the E2E suite logs in as (test env only)"
  task create_e2e_admin: :environment do
    raise "refusing to run outside RAILS_ENV=test" unless Rails.env.test?

    username = ENV.fetch("E2E_ADMIN_USERNAME", "e2e_admin")
    password = ENV.fetch("E2E_ADMIN_PASSWORD", "e2e_password123")

    user = User.find_or_initialize_by(username: username)
    user.update!(name: "Administrador E2E", password: password, role: "administrador")

    puts "E2E admin ready: #{username}"
  end
end
