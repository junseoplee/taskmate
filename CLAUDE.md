# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

TaskMate is a microservices-based task management application built with Ruby on Rails 8. The project consists of 4 independent services that will run in a Kubernetes environment.

## Ruby Environment

The project uses Ruby 3.4.3 via rbenv with Rails 8.0.2.

## Project Structure

```
taskmate/
├── services/           # Microservices (to be created)
│   ├── user-service/
│   ├── task-service/
│   ├── analytics-service/
│   └── file-service/
├── k8s/               # Kubernetes configurations (to be created)
├── docker/            # Docker configurations (to be created)
└── docs/              # Documentation
```

## Development Setup

### Prerequisites
- Ruby 3.4.3 (via rbenv)
- Rails 8.0.2
- PostgreSQL
- Redis
- Docker
- minikube

### Running the Application

```bash
# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate

# Run development server
bin/dev
```

## Microservices Architecture

### Services and Ports
- User Service: Port 3000 (Authentication & Session Management)
- Task Service: Port 3001 (Task CRUD Operations)
- Analytics Service: Port 3002 (Statistics & Dashboard)
- File Service: Port 3003 (File Attachments)

### Communication Patterns
- Synchronous: REST API calls between services
- Asynchronous: Event-driven updates for analytics
- Authentication: Session-based with cookies

## Development Principles

### Implementation Principles

- **Test-First Development**: Always write tests before implementing business logic. Follow TDD practices.
- **SOLID Principles**: Strictly adhere to object-oriented design principles.
- **Clean Architecture**: Manage dependency directions properly and maintain clear separation of concerns between layers.
- **DRY Principle**: Prevent duplication by reusing existing functionality wherever possible.

### Code Quality Standards

- **Simplicity First**: Always prefer the simplest solution over complex ones.
- **Guard Rails**: Never use mock data in development or production environments (test environments only).
- **Efficiency**: Minimize token usage and optimize output without sacrificing code clarity.

### Refactoring Guidelines

- **Prior Approval Required**: Before any refactoring, explain the plan and get explicit approval.
- **Structure Improvement Focus**: Refactoring should improve code structure, not change functionality.
- **Test Verification**: After refactoring, verify all tests pass without modification.

### Debugging Practices

- **Share Root Causes**: When debugging, explain both the problem's root cause and the solution.
- **Accurate Diagnosis**: Focus on identifying the exact cause rather than applying temporary fixes.
- **Correctness Over Error Suppression**: The goal is proper functionality, not just eliminating error messages.

## Testing Strategy

- Use RSpec for unit and integration tests
- Follow the AAA pattern (Arrange, Act, Assert)
- Maintain test coverage above 80%
- Test service interactions thoroughly

## Git Workflow

- Main branch for stable code
- Feature branches for new development
- Descriptive commit messages
- Regular commits with atomic changes

## Important Notes

- This is a graduation project for demonstration purposes
- Local development and testing only (no production deployment)
- All services use Rails 8 with session-based authentication
- Focus on microservices architecture patterns and Kubernetes deployment