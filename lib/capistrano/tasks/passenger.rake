# Restart Passenger standalone (not Passenger-in-nginx).
# The gem's built-in restart only touches tmp/restart.txt which works for
# Passenger as an nginx module but NOT for Passenger standalone.
namespace :passenger do
  desc 'Restart Passenger standalone server'
  task :restart do
    on roles(:app) do
      rbenv_prefix = fetch(:rbenv_prefix)
      within release_path do
        execute "#{rbenv_prefix} bundle exec passenger stop --port 3000 || true"
        execute "#{rbenv_prefix} bundle exec passenger start " \
                "--port 3000 --environment production --daemonize"
      end
    end
  end
end

# Override the default passenger:restart hook so Capistrano calls ours instead.
Capistrano::DSL.stages.each do |stage|
  after "#{stage}", 'passenger:restart'
end

after 'deploy:publishing', 'passenger:restart'
