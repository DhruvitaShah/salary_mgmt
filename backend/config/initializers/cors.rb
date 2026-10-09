# Only needed when the Angular dev server (http://localhost:4200) talks to the API directly.
# In production the SPA and API share one origin, so no CORS headers are required.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("CORS_ORIGINS", "http://localhost:4200").split(",")
    resource "/api/*", headers: :any, methods: %i[get post patch put delete options], credentials: true
  end
end
