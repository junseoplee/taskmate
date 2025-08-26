#!/bin/bash

echo "🛑 Stopping all services..."
docker-compose down

echo "🧹 Cleaning up unused images..."
docker system prune -f

echo "🔨 Building all services..."
docker-compose build

echo "🚀 Starting all services..."
docker-compose up -d

echo "⏳ Waiting for services to be ready..."
sleep 15

echo "🔍 Checking service health..."
curl -s http://localhost:3000/up && echo "✅ User Service: OK" || echo "❌ User Service: Failed"
curl -s http://localhost:3001/up && echo "✅ Task Service: OK" || echo "❌ Task Service: Failed"
curl -s http://localhost:3002/up && echo "✅ Analytics Service: OK" || echo "❌ Analytics Service: Failed"
curl -s http://localhost:3003/up && echo "✅ File Service: OK" || echo "❌ File Service: Failed"
curl -s http://localhost:3100/up && echo "✅ Frontend Service: OK" || echo "❌ Frontend Service: Failed"

echo "🎉 All services restarted!"