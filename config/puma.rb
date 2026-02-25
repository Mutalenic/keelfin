# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
# Optimized for 1GB RAM server
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 2 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { 1 }
threads min_threads_count, max_threads_count

# Specifies the `worker_timeout` threshold that Puma will use to wait before
# terminating a worker in development environments.
#
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# Production configuration
if ENV.fetch("RAILS_ENV") { "development" } == "production"
  # Bind to Unix socket for NGINX
  bind "unix://home/deploy/keelfin/shared/tmp/sockets/puma.sock"
  
  # Single worker for 1GB RAM
  workers 1
  
  # Preload app for memory efficiency
  preload_app!
  
  # Production paths
  pidfile "/home/deploy/keelfin/shared/tmp/pids/puma.pid"
  state_path "/home/deploy/keelfin/shared/tmp/pids/puma.state"
  
  # Logging
  stdout_redirect "/home/deploy/keelfin/shared/log/puma.stdout.log", "/home/deploy/keelfin/shared/log/puma.stderr.log", true
else
  # Development configuration
  port ENV.fetch("PORT") { 3000 }
  pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }
end

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV") { "development" }

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart
