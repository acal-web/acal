require "dotenv"

# Only load .env files if NOT running in a Docker container.
# In containerized production, env vars are injected by orchestration (Kubernetes, Docker, etc).
# Check for /.dockerenv file which exists in Docker containers.
is_containerized = File.exist?("/.dockerenv")

unless is_containerized
  # Load .env (shared configuration)
  Dotenv.load(".env")

  # Load environment-specific .env files
  case Rails.env
  when "development"
    Dotenv.load(".env.development", ".env.local")
  when "test"
    Dotenv.load(".env.test")
  when "production"
    # Load .env.production for local production testing (not in Docker)
    Dotenv.load(".env.production") if File.exist?(".env.production")
  end
end
