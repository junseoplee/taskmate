# TaskMate Setup Guide

## Prerequisites

- Docker and Docker Compose
- Ruby 3.4.3 (for local development)
- Git

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/junseoplee/taskmate.git
   cd taskmate
   ```

2. **Run setup script**
   ```bash
   ./scripts/setup.sh
   ```

3. **Start development environment**
   ```bash
   ./scripts/dev.sh
   ```

## Development Workflow

### Starting Services

```bash
# Start only infrastructure (PostgreSQL + Redis)
docker-compose up -d postgres redis

# Start all microservices
./scripts/dev.sh
```

### Building Services

```bash
# Build all services
./scripts/build.sh

# Build specific service
./scripts/build.sh user-service
```

### Running Tests

```bash
# Run all tests
./scripts/test.sh

# Run specific service tests
./scripts/test.sh user-service
```

### Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (data will be lost)
docker-compose down -v
```

## Service URLs

- **User Service**: http://localhost:3000
- **Task Service**: http://localhost:3001
- **Analytics Service**: http://localhost:3002
- **File Service**: http://localhost:3003
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## Database Access

```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U taskmate -d user_service_db

# List all databases
docker-compose exec postgres psql -U taskmate -d postgres -c "\l"

# Connect to Redis
docker-compose exec redis redis-cli
```

## Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   # Check what's using the port
   lsof -i :3000
   
   # Kill the process
   kill -9 <PID>
   ```

2. **Database connection failed**
   ```bash
   # Check PostgreSQL logs
   docker-compose logs postgres
   
   # Restart PostgreSQL
   docker-compose restart postgres
   ```

3. **Services not starting**
   ```bash
   # Check all container logs
   docker-compose logs
   
   # Rebuild and restart
   docker-compose down
   ./scripts/setup.sh
   ```

### Log Files

```bash
# View service logs
docker-compose logs user-service
docker-compose logs task-service
docker-compose logs postgres
docker-compose logs redis

# Follow logs in real-time
docker-compose logs -f user-service
```

## Development Tips

- Use `docker-compose --profile services up` to start only microservices
- Environment variables are loaded from `.env` file
- Database schemas are automatically created on first run
- Hot reloading is enabled for all Rails services