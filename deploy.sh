#!/bin/bash

# OTW Archive Deployment Script
# This script helps deploy the OTW Archive application

set -e

echo "🚀 Starting OTW Archive Deployment"

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please copy .env.example to .env and configure your environment variables."
    exit 1
fi

# Load environment variables
set -a
source .env
set +a

echo "📦 Building Docker images..."
docker compose -f docker-compose.prod.yml build

echo "🗃️ Starting database..."
docker compose -f docker-compose.prod.yml up -d db

echo "⏳ Waiting for database to be ready..."
sleep 30

echo "🗃️ Running database migrations..."
docker compose -f docker-compose.prod.yml run --rm web bundle exec rake db:create db:migrate

echo "🔍 Setting up Elasticsearch..."
docker compose -f docker-compose.prod.yml up -d elasticsearch
sleep 30

echo "🔍 Creating Elasticsearch indexes..."
docker compose -f docker-compose.prod.yml run --rm web bundle exec rake search:index

echo "📦 Precompiling assets..."
docker compose -f docker-compose.prod.yml run --rm web bundle exec rake assets:precompile

echo "🚀 Starting all services..."
docker compose -f docker-compose.prod.yml up -d

echo "✅ Deployment completed!"
echo "🌐 Your application should be available at http://localhost:3000"
echo ""
echo "📋 Useful commands:"
echo "  View logs: docker compose -f docker-compose.prod.yml logs -f"
echo "  Stop services: docker compose -f docker-compose.prod.yml down"
echo "  Restart web: docker compose -f docker-compose.prod.yml restart web"
echo "  Run migrations: docker compose -f docker-compose.prod.yml run --rm web bundle exec rake db:migrate"