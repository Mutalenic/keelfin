require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Keelfin
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Background jobs: Sidekiq when Redis is configured (REDIS_URL);
    # otherwise run jobs in-process with the async adapter, e.g. on free-tier
    # hosting without a worker process or local development without Redis.
    # Test keeps jobs inspectable via enqueued_jobs.
    config.active_job.queue_adapter = if Rails.env.test?
                                        :test
                                      elsif ENV['REDIS_URL'].present?
                                        :sidekiq
                                      else
                                        :async
                                      end
  end
end
