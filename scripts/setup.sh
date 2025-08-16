#!/bin/bash

set -e

echo "🚀 TaskMate Project Setup"
echo "========================="

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose >/dev/null 2>&1; then
    echo "❌ docker-compose is not installed. Please install it and try again."
    exit 1
fi

echo "✅ Docker is running"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📄 Creating .env file from template..."
    cp .env.example .env
fi

# Start infrastructure services
echo "🐘 Starting PostgreSQL and Redis..."
docker-compose up -d postgres redis

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
until docker-compose exec postgres pg_isready -U taskmate >/dev/null 2>&1; do
    echo "Waiting for PostgreSQL..."
    sleep 2
done

until docker-compose exec redis redis-cli ping >/dev/null 2>&1; do
    echo "Waiting for Redis..."
    sleep 2
done

echo "✅ Infrastructure services are ready!"

# Check if databases were created
echo "🔍 Verifying database creation..."
docker-compose exec postgres psql -U taskmate -d postgres -c "\l" | grep "_service_db" || {
    echo "❌ Databases were not created properly. Check the logs:"
    docker-compose logs postgres
    exit 1
}

echo "✅ All databases created successfully!"

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Run './scripts/dev.sh' to start all services"
echo "2. Or run 'docker-compose --profile services up' to start microservices"
echo ""
echo "Available services:"
echo "- PostgreSQL: localhost:5432"
echo "- Redis: localhost:6379"
echo "- User Service: localhost:3000 (when started)"
echo "- Task Service: localhost:3001 (when started)"
echo "- Analytics Service: localhost:3002 (when started)"
echo "- File Service: localhost:3003 (when started)"