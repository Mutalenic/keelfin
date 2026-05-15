# Restart Passenger standalone (not Passenger-in-nginx).
# The gem's built-in restart only touches tmp/restart.txt which works for
# Passenger as an nginx module but NOT for Passenger standalone.
namespace :passenger do
  desc 'Restart Passenger standalone server (optional)'
  task :standalone_restart do
    next unless fetch(:passenger_standalone, false)

    on roles(:app) do
      rbenv_prefix = fetch(:rbenv_prefix)
      app_path = fetch(:passenger_app_path, current_path)

      within app_path do
        execute "#{rbenv_prefix} bundle exec passenger stop --port 3000 || true"
        sleep 2
        execute "#{rbenv_prefix} bundle exec passenger start " \
                '--port 3000 --environment production --daemonize'
      end
    end
  end
end

after 'deploy:finishing', 'passenger:standalone_restart'
