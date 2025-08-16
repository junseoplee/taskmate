#!/bin/bash

set -e

echo "🚀 Starting TaskMate Development Environment"
echo "============================================="

# Check if infrastructure is running
if ! docker-compose ps postgres | grep "Up" >/dev/null 2>&1; then
    echo "🐘 Starting infrastructure services..."
    docker-compose up -d postgres redis
    
    echo "⏳ Waiting for services to be ready..."
    until docker-compose exec postgres pg_isready -U taskmate >/dev/null 2>&1; do
        echo "Waiting for PostgreSQL..."
        sleep 2
    done
    
    until docker-compose exec redis redis-cli ping >/dev/null 2>&1; do
        echo "Waiting for Redis..."
        sleep 2
    done
fi

echo "✅ Infrastructure services are ready!"

# Start all microservices
echo "🏗️ Starting all microservices..."
docker-compose --profile services up --build

echo "🎉 All services are running!"
echo ""
echo "Available endpoints:"
echo "- User Service: http://localhost:3000"
echo "- Task Service: http://localhost:3001"  
echo "- Analytics Service: http://localhost:3002"
echo "- File Service: http://localhost:3003"
echo ""
echo "To stop all services: docker-compose down"