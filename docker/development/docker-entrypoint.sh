#!/bin/bash
set -e

# Extract service name from DATABASE_URL or use default
SERVICE_NAME=${DATABASE_URL##**/}
SERVICE_NAME=${SERVICE_NAME%%\?*}
SERVICE_NAME=${SERVICE_NAME%%_*}

echo "🚀 Starting ${SERVICE_NAME} service initialization..."

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL..."
until pg_isready -h postgres -p 5432 -U taskmate >/dev/null 2>&1; do
  echo "   PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo "✅ PostgreSQL is ready!"

# Wait for Redis to be ready
echo "⏳ Waiting for Redis..."
until redis-cli -h redis ping >/dev/null 2>&1; do
  echo "   Redis is unavailable - sleeping"
  sleep 1
done
echo "✅ Redis is ready!"

# Database setup
echo "🗄️  Setting up database..."
if ! rails db:version >/dev/null 2>&1; then
  echo "   Creating database..."
  rails db:create
  echo "   Running migrations..."
  rails db:migrate
  if [ "$RAILS_ENV" = "development" ]; then
    echo "   Seeding database..."
    rails db:seed || echo "   No seeds found or seeding failed"
  fi
else
  echo "   Database exists. Running pending migrations..."
  rails db:migrate
fi

# Pre-compile assets if needed (for services that use them)
if [ -f "app/assets" ] && [ "$RAILS_ENV" = "production" ]; then
  echo "🎨 Pre-compiling assets..."
  rails assets:precompile
fi

echo "✅ ${SERVICE_NAME} service initialization completed!"
echo "🌐 Starting Rails server..."

# Execute the main command
exec "$@"