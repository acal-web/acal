namespace :test do
  desc "Truncate all app tables in the test DB (used by Maestro E2E runs / local debugging)"
  task reset_db: :environment do
    Test::DatabaseReset.call
    puts "test DB reset."
  end
end
