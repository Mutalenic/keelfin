# Restart Passenger standalone (not Passenger-in-nginx).
# For Passenger standalone, touching tmp/restart.txt may not fully reload.
# We force a full stop/start cycle to ensure code is reloaded.
namespace :passenger do # rubocop:disable Metrics/BlockLength
  desc 'Force restart Passenger standalone server'
  task :force_restart do
    on roles(:app) do
      rbenv_prefix = fetch(:rbenv_prefix)
      app_path = fetch(:passenger_app_path, current_path)

      within app_path do
        execute "#{rbenv_prefix} bundle exec passenger stop --port 3000 || true"
        sleep 3
        execute "#{rbenv_prefix} bundle exec passenger start " \
                '--port 3000 --environment production --daemonize'
      end
    end
  end

  desc 'Smoke test: verify app is responding after deployment'
  task :smoke_test do
    on roles(:app) do
      sleep 5

      app_url = 'http://localhost:3000'
      info "Testing app at #{app_url}..."

      result = capture "curl -s -o /dev/null -w '%{http_code}' #{app_url} || echo '000'", raise_on_non_zero_exit: false # rubocop:disable Style/FormatStringToken
      http_code = result.strip

      if http_code =~ /^[23]/
        info "✓ Smoke test passed (HTTP #{http_code})"
      elsif %w[500 000].include?(http_code)
        error "❌ Smoke test failed (HTTP #{http_code}) — check production logs"
        exit 1
      else
        warn "⚠ Smoke test: unexpected HTTP #{http_code}"
      end
    end
  end
end # rubocop:enable Metrics/BlockLength

after 'deploy:finishing', 'passenger:smoke_test'
