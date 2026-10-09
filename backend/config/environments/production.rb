require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.cache_store = :memory_store

  # The Angular build is copied to public/ and served by Rails (single deployable).
  config.public_file_server.enabled = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=31536000" }

  # TLS is terminated by the hosting platform's load balancer.
  config.assume_ssl = true
  config.force_ssl = ENV.fetch("FORCE_SSL", "true") == "true"
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.logger($stdout)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
end
