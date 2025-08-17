#!/bin/bash
set -e

# Extract database connection info from DATABASE_URL
DB_HOST=${DATABASE_HOST:-postgres}
DB_PORT=${DATABASE_PORT:-5432}
DB_USER=${DATABASE_USER:-taskmate}

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER"; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done
echo "PostgreSQL is up - executing command"

# Check if database exists, create if not
echo "Checking database..."
if ! ./bin/rails db:version >/dev/null 2>&1; then
  echo "Database does not exist. Creating..."
  ./bin/rails db:create
  ./bin/rails db:migrate
else
  echo "Database exists. Running migrations..."
  ./bin/rails db:migrate
fi

# Seed database if needed
if [ "$RAILS_ENV" = "development" ]; then
  echo "Seeding database..."
  ./bin/rails db:seed
fi

echo "Starting Task Service..."
exec "$@"