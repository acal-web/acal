# Only load dotenv in environments where it's bundled (development/test).
# In production, env vars are injected by orchestration (Kubernetes, Docker, etc).
if Gem.loaded_specs["dotenv"]
  require "dotenv"

  Dotenv.load(".env")

  case Rails.env
  when "development"
    Dotenv.load(".env.development", ".env.local")
  when "test"
    Dotenv.load(".env.test")
  when "production"
    Dotenv.load(".env.production") if File.exist?(".env.production")
  end
end
