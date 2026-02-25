# DigitalOcean Production Server
server "144.126.239.114", user: "deploy", roles: %w{app db web}

# Production-specific configuration
set :rails_env, "production"
set :branch, "develop"
