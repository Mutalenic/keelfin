# config valid for current version and patch releases of Capistrano
lock "~> 3.20.0"

set :application, "keelfin"
set :repo_url, "git@github.com:Mutalenic/keelfin.git"

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Deploy to user's home directory
set :deploy_to, "/home/deploy/#{fetch(:application)}"

# rbenv configuration
set :rbenv_type, :user
set :rbenv_ruby, '3.3.5'
set :rbenv_path, '/home/deploy/.rbenv'
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"

# Default value for :linked_files
append :linked_files, "config/database.yml", "config/master.key"

# Default value for linked_dirs
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "vendor", "storage"

# Keep only 3 releases
set :keep_releases, 3

# Skip asset precompilation for now
Rake::Task["deploy:assets:precompile"].clear_actions

# Puma configuration
set :puma_threads, [1, 2]
set :puma_workers, 1
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log, "#{release_path}/log/puma.access.log"
set :puma_preload_app, true

# Default value for :pty is false
set :pty, true

# Default value for default_env is {}
set :default_env, { 
  path: "/home/deploy/.rbenv/shims:/home/deploy/.rbenv/bin:$PATH",
  RAILS_ENV: "production"
}

# SSH options for DigitalOcean
set :ssh_options, {
  forward_agent: true,
  auth_methods: %w[publickey],
  user: 'deploy'
}
