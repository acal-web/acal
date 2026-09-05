namespace :test do
  desc "Truncate all app tables in the test DB (used by the Patrol/integration_test E2E suite / local debugging)"
  task reset_db: :environment do
    Test::DatabaseReset.call
    puts "test DB reset."
  end
end
