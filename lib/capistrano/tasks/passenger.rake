# Restart Passenger standalone (not Passenger-in-nginx).
# For Passenger standalone, touching tmp/restart.txt may not fully reload.
# We force a full stop/start cycle to ensure code is reloaded.
namespace :passenger do
  desc 'Force restart Passenger standalone server'
  task :force_restart do
    on roles(:app) do
      rbenv = fetch(:rbenv_prefix)
      gemfile = "#{fetch(:deploy_to)}/current/Gemfile"

      pid_file = "#{fetch(:deploy_to)}/shared/tmp/pids/passenger.3000.pid"
      execute "BUNDLE_GEMFILE=#{gemfile} #{rbenv} bundle exec passenger stop --pid-file #{pid_file} || true"
      sleep 3
      execute "BUNDLE_GEMFILE=#{gemfile} #{rbenv} bundle exec passenger start " \
              '--port 3000 --environment production --daemonize'
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
end

# Override the capistrano/passenger gem's restart task — force_restart
# handles the full stop/start cycle after deploy:symlink:release.
Rake::Task['passenger:restart'].clear_actions if Rake::Task.task_defined?('passenger:restart')
namespace :passenger do
  task :restart do
    # no-op: handled by passenger:force_restart below
  end
end

after 'deploy:symlink:release', 'passenger:force_restart'
after 'deploy:finishing', 'passenger:smoke_test'
