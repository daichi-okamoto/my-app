# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.0
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

# Rails app lives here
WORKDIR /rails

# Set environment variables by default
ARG RAILS_ENV=production
ENV RAILS_ENV="${RAILS_ENV}" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle"

# Set BUNDLE_WITHOUT based on the environment
RUN if [ "$RAILS_ENV" = "production" ]; then \
      echo "BUNDLE_WITHOUT=development test" >> /etc/environment; \
    else \
      echo "BUNDLE_WITHOUT=" >> /etc/environment; \
    fi
ENV BUNDLE_WITHOUT="${BUNDLE_WITHOUT}"

# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems and Python/OR-Tools
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libvips \
    pkg-config \
    libpq-dev \
    python3 \
    python3-pip \
    nodejs \
    yarn

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Install Python and OR-Tools
RUN pip3 install ortools

# Copy application code
COPY . .

# Tailwind CSS configuration
COPY ./tailwind.config.js ./postcss.config.js ./

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN if [ "$RAILS_ENV" = "production" ]; then \
      SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile; \
    fi

# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libsqlite3-0 \
    libvips \
    libpq5 \
    python3 \
    python3-pip && \
    pip3 install ortools && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER rails:rails

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
