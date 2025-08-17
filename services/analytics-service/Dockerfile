# Analytics Service Dockerfile for Development
FROM ruby:3.4.3-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    postgresql-client \
    libpq-dev \
    libyaml-dev \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV RAILS_ENV=development
ENV BUNDLE_PATH=/usr/local/bundle

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Ensure gems are properly installed for runtime
RUN bundle config set --local deployment false && \
    bundle install --jobs 4 --retry 3

# Create startup script and set permissions
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /app

USER rails

# Expose port 3002 for Analytics Service
EXPOSE 3002

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3002"]