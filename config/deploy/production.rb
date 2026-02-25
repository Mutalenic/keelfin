# DigitalOcean Production Server
server "144.126.239.114", user: "deploy", roles: %w{app db web}

# Production-specific configuration
set :rails_env, "production"
set :branch, "main"

# Set environment variables
set :default_env, {
  'SECRET_KEY_BASE' => '74e886ef19b4aadc1ca42bfff4555e447d84f48014446e336201054aefe226e01b961c5ccd291201aaebe638a23a471816867e7c1621054dff79849f91b4a53e'
}
