# ---- 1. Build the Angular app ----
FROM node:22-slim AS web
WORKDIR /web
COPY frontend/package.json ./
RUN npm install --no-audit --no-fund
COPY frontend/ ./
RUN npx ng build --configuration production

# ---- 2. Rails API that also serves the built Angular app from public/ ----
FROM ruby:3.3-slim AS app
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential libpq-dev libyaml-dev git curl && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /rails
ENV RAILS_ENV=production \
    BUNDLE_WITHOUT="development:test" \
    RAILS_LOG_TO_STDOUT=1

COPY backend/Gemfile backend/Gemfile.lock* ./
RUN bundle install --jobs 4 && rm -rf ~/.bundle/cache

COPY backend/ ./
COPY --from=web /web/dist/ ./public/

EXPOSE 3000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
