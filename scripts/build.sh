#!/bin/bash

set -e

echo "🏗️ Building TaskMate Docker Images"
echo "==================================="

# Default to building all services
SERVICES=${1:-"user-service task-service analytics-service file-service"}

echo "📦 Building services: $SERVICES"
echo ""

for service in $SERVICES; do
    if [ -d "services/$service" ]; then
        echo "Building $service..."
        echo "==================="
        
        docker-compose build $service
        
        echo "✅ $service build completed"
        echo ""
    else
        echo "⚠️ Service directory 'services/$service' not found, skipping..."
    fi
done

echo "🎉 All builds completed!"
echo ""
echo "To start services: ./scripts/dev.sh"
echo "To run tests: ./scripts/test.sh"