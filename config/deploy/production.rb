# DigitalOcean Production Server
server "144.126.239.114", user: "deploy", roles: %w{app db web}

# Production-specific configuration
set :rails_env, "production"
set :branch, "main"

# Enable Passenger standalone restart task
set :passenger_standalone, true
set :passenger_app_path, -> { current_path }

# Environment variables (SECRET_KEY_BASE and other secrets are loaded from the
# server's shared/.env file via dotenv-rails — do NOT hardcode secrets here)
