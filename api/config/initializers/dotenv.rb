require "dotenv"

# Load .env (shared configuration)
Dotenv.load(".env")

# Load environment-specific .env files
case Rails.env
when "development"
  Dotenv.load(".env.development", ".env.local")
when "test"
  Dotenv.load(".env.test")
when "production"
  # Load .env.production if it exists (useful for local production testing)
  Dotenv.load(".env.production") if File.exist?(".env.production")
end
