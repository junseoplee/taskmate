#!/bin/bash

set -e

echo "🧪 Running TaskMate Test Suite"
echo "==============================="

# Start test infrastructure if not running
if ! docker-compose ps postgres | grep "Up" >/dev/null 2>&1; then
    echo "🐘 Starting test infrastructure..."
    docker-compose up -d postgres redis
    
    echo "⏳ Waiting for services to be ready..."
    until docker-compose exec postgres pg_isready -U taskmate >/dev/null 2>&1; do
        echo "Waiting for PostgreSQL..."
        sleep 2
    done
fi

# Default to running all service tests
SERVICES=${1:-"user-service task-service analytics-service file-service"}

echo "🔍 Running tests for services: $SERVICES"
echo ""

for service in $SERVICES; do
    if [ -d "services/$service" ]; then
        echo "Testing $service..."
        echo "==================="
        
        # Run tests in container
        docker-compose run --rm \
            -e RAILS_ENV=test \
            -e DATABASE_URL=postgresql://taskmate:password@postgres:5432/${service//-/_}_test \
            $service \
            bash -c "
                bundle exec rails db:create db:migrate RAILS_ENV=test || true
                bundle exec rspec --format documentation
            "
        
        echo "✅ $service tests completed"
        echo ""
    else
        echo "⚠️ Service directory 'services/$service' not found, skipping..."
    fi
done

echo "🎉 All tests completed!"