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
- Docker & Docker Compose
- minikube

### 🚀 Quick Start

#### 1. Start All Services with Docker Compose
```bash
# From project root
cd /Users/junseop/Documents/work/taskmate

# Start all services (PostgreSQL, Redis, User, Task, Analytics, File)
docker-compose up -d

# Check services status
docker-compose ps

# View logs for specific service
docker-compose logs [service-name]
```

#### 2. Stop All Services
```bash
docker-compose down
```

### Manual Development (Without Docker)

#### 1. Start Infrastructure
```bash
# Start PostgreSQL and Redis only
docker-compose up -d postgres redis
```

#### 2. Run Individual Services
```bash
# User Service
cd services/user-service
bundle install
rails db:create db:migrate
rails server -p 3000

# Task Service  
cd services/task-service
bundle install
rails db:create db:migrate
rails server -p 3001

# Analytics Service
cd services/analytics-service
bundle install
rails db:create db:migrate
rails server -p 3002

# File Service
cd services/file-service
bundle install
rails db:create db:migrate
rails server -p 3003
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

### Docker Configuration
- All services use Ruby 3.4.3-slim base image
- Each service has its own Dockerfile/Dockerfile.dev
- Services are networked via `taskmate_network`
- Persistent volumes for PostgreSQL data and file uploads
- Health checks for PostgreSQL and Redis dependencies

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

## TDD Development Methodology

### Core TDD Principles

**Red-Green-Refactor Cycle**:
1. **Red**: Write a failing test first
2. **Green**: Write minimal code to pass the test
3. **Refactor**: Improve code quality while keeping tests passing

**Test Quality Standards**:
- **Test Coverage**: Minimum 80% unit tests, 70% integration tests
- **Test Speed**: Complete test suite under 30 seconds
- **Test Reliability**: 99% success rate in CI/CD

### Testing Strategy

- Use RSpec for unit and integration tests
- Follow the AAA pattern (Arrange, Act, Assert)  
- Maintain test coverage above 80%
- Test service interactions thoroughly

### Test Environment Setup

All services use the following testing stack:

```ruby
# Gemfile (development/test groups)
group :development, :test do
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'faker', '~> 3.0'
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'shoulda-matchers', '~> 5.3'
  gem 'webmock', '~> 3.18'
  gem 'vcr', '~> 6.1'
  gem 'timecop', '~> 0.9'
end

group :test do
  gem 'simplecov', '~> 0.22', require: false
  gem 'rspec-json_expectations', '~> 2.2'
end
```

### Testing Layers

1. **Unit Tests**: Models, Services, individual methods
2. **Controller Tests**: API endpoints, authentication, authorization
3. **Integration Tests**: Service-to-service communication
4. **E2E Tests**: Complete user workflows

### Testing Best Practices

**Test Isolation**:
- Database Cleaner for data cleanup between tests
- WebMock for external API mocking
- Timecop for time-dependent test consistency

**Performance Testing**:
- API response times should be under 200ms
- Concurrent request handling under 300ms average
- Memory usage monitoring for heavy operations

**Error Scenario Testing**:
- Network timeouts and failures
- Service unavailability scenarios
- Invalid data format handling

## Monorepo Architecture Guide

### Service Port Management Strategy

| 서비스 | 포트 | 역할 | 상태 |
|--------|------|------|------|
| User Service | 3000 | 인증 & 세션 관리 | ✅ 구현완료 |
| Task Service | 3001 | 태스크 CRUD | ✅ 구현완료 |
| Analytics Service | 3002 | 통계 & 대시보드 | ✅ 구현완료 |
| File Service | 3003 | 파일 첨부 | ✅ 구현완료 |

### Service Independence Principles

**Complete Independence**:
- ✅ 각자의 Gemfile과 의존성 관리
- ✅ 독립적인 데이터베이스 (멀티 DB 구조)
- ✅ 별도 포트에서 실행
- ✅ 독립적인 테스트 슈트
- ✅ 개별 배포 가능

### Multi-Database Architecture

```
PostgreSQL (단일 인스턴스)
├── user_service_db           # User, Session 테이블
├── task_service_db          # Task, Project 테이블
├── analytics_service_db     # Analytics 테이블  
└── file_service_db          # File, Attachment 테이블
```

각 서비스의 database.yml:
```yaml
development:
  adapter: postgresql
  database: user_service_db    # 서비스별로 다름
  username: taskmate
  password: password
  host: localhost
  port: 5432
```

### Development Workflow Management

#### 전체 인프라 시작
```bash
# 루트 디렉토리에서
docker-compose up -d

# 확인
docker-compose ps
```

#### 개별 서비스 실행
```bash
# User Service
cd services/user-service
rails server -p 3000

# Task Service
cd services/task-service  
rails server -p 3001

# Analytics Service
cd services/analytics-service
rails server -p 3002

# File Service
cd services/file-service
rails server -p 3003
```

#### 동시 실행 관리
```bash
# 각 서비스를 백그라운드로 실행
cd services/user-service && rails server -p 3000 -d
cd services/task-service && rails server -p 3001 -d
cd services/analytics-service && rails server -p 3002 -d
cd services/file-service && rails server -p 3003 -d

# 프로세스 확인
ps aux | grep rails

# 모든 Rails 서버 종료
pkill -f "rails server"
```

### Inter-Service Communication Patterns

#### 1. 동기 통신 (REST API)
```bash
# User Service → Task Service 인증 검증
curl http://localhost:3001/api/v1/tasks \
  -H "Authorization: Bearer session_token_here"

# Task Service에서 User 검증
curl http://localhost:3000/api/v1/auth/verify \
  -H "Authorization: Bearer session_token_here"
```

#### 2. 비동기 통신 (Redis 이벤트)
```ruby
# User Service에서 이벤트 발행
Redis.current.publish("user.created", {
  user_id: user.id,
  email: user.email
}.to_json)

# Analytics Service에서 이벤트 구독
Redis.current.subscribe("user.created") do |on|
  on.message do |channel, message|
    # 사용자 생성 이벤트 처리
  end
end
```

#### 3. 인증 통합 패턴
- **HTTP Header 기반**: Authorization Bearer 토큰 방식
- **Session 검증**: User Service의 검증 API 호출
- **Circuit Breaker**: AuthService에서 재시도 로직 및 에러 처리
- **Timeout 관리**: 5초 기본 타임아웃, 3회 재시도

### Service Quality Gates

#### Port Conflict Prevention
```bash
# 포트 사용 확인
lsof -i :3000
lsof -i :3001
lsof -i :3002
lsof -i :3003

# 프로세스 종료
kill -9 <PID>
```

#### Ruby Version Management
```bash
# 모든 서비스는 동일한 Ruby 버전 사용
ruby -v
# ruby 3.4.3

# rbenv로 버전 고정
echo "3.4.3" > .ruby-version
```

#### Test Isolation Strategy
```bash
# 각 서비스 테스트는 독립적으로 실행
cd services/user-service && bundle exec rspec
cd services/task-service && bundle exec rspec
cd services/analytics-service && bundle exec rspec
cd services/file-service && bundle exec rspec
```

### Monitoring and Debugging

#### Health Check Endpoints
```bash
# 모든 서비스 헬스체크
curl http://localhost:3000/up  # User Service
curl http://localhost:3001/up  # Task Service
curl http://localhost:3002/up  # Analytics Service
curl http://localhost:3003/up  # File Service
```

#### Service Log Management
```bash
# 각 서비스 로그 확인
tail -f services/user-service/log/development.log
tail -f services/task-service/log/development.log

# Docker 서비스 로그
docker-compose logs postgres
docker-compose logs redis
```

#### Data Consistency Principles
- 각 서비스는 자신의 데이터만 소유
- 서비스 간 데이터 공유는 API 통신으로만
- Eventually Consistent 모델 적용
- API 버전 관리 (/api/v1/) 및 하위 호환성 유지

### 🧪 Testing Commands by Service

```bash
# User Service Tests (recommended)
cd services/user-service
./pre_commit_check.sh  # 자동화된 전체 검증

# 또는 개별 실행
bundle exec rspec      # 테스트 실행
bundle exec rubocop    # 코드 스타일 검사

# Task Service Tests (when available)
cd services/task-service  
bundle exec rspec

# Full Project Tests
./scripts/test.sh
```

### API Testing

#### Using Docker Compose
```bash
# Start all services
docker-compose up -d

# Test User Service
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"홍길동","email":"hong@example.com","password":"password123","password_confirmation":"password123"}'

# Test Task Service
curl -s http://localhost:3001/api/v1/tasks

# Test Analytics Service  
curl -s http://localhost:3002/api/v1/analytics/dashboard

# Test File Service
curl -s http://localhost:3003/api/v1/file_categories
```

#### Manual API Testing
```bash
# 1. 회원가입 테스트
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{
    "name": "홍길동",
    "email": "hong@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'

# 2. 로그인 테스트
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{
    "email": "hong@example.com",
    "password": "password123"
  }'

# 3. 세션 검증 테스트
curl -X GET http://localhost:3000/api/v1/auth/verify \
  -H "Content-Type: application/json" \
  -b cookies.txt

# 4. 로그아웃 테스트
curl -X POST http://localhost:3000/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -b cookies.txt
```

## Git Workflow

- Main branch for stable code
- Feature branches for new development
- Descriptive commit messages
- Regular commits with atomic changes

### ⚠️ **CRITICAL: Monorepo Commit Rules**

**MANDATORY**: All commits MUST be made from the project root directory to maintain proper Monorepo structure.

#### **Correct Workflow (Frontend Development Example)**
```bash
# ✅ CORRECT: Work in service directory, commit from root
1. cd services/frontend-service           # Work in service directory
2. # Implement features, edit views, controllers...
3. cd /Users/junseop/Documents/work/taskmate  # ✅ RETURN TO ROOT!
4. git add services/frontend-service/     # Stage all changes
5. git add docs/PROJECT_PLAN.md          # Update docs if needed
6. git status                            # Verify changes
7. git commit -m "feat(frontend): ..."   # Commit from ROOT
```

#### **❌ WRONG: Never commit from service directory**
```bash
# ❌ WRONG: This will create incomplete commits
cd services/frontend-service
git add .          # ❌ Only stages service files
git commit -m "..."  # ❌ Partial commit, missing context
```

#### **Why Root Commits Are Critical**
- **Monorepo Integrity**: All services managed in single repository
- **Consistent History**: Complete change tracking across services
- **Dependency Management**: Cross-service changes in single commit
- **CI/CD Pipeline**: Build/deployment based on root-level changes
- **Documentation Sync**: Keep PROJECT_PLAN.md updated with code changes

#### **Service-Specific Commit Checklist**
```bash
✅ Pre-Commit Checklist:
□ Feature implementation completed
□ cd /Users/junseop/Documents/work/taskmate  # ROOT DIRECTORY
□ git status  # Verify all intended changes
□ git add services/[service-name]/
□ Update docs/PROJECT_PLAN.md if needed
□ git commit -m "proper conventional message"
□ Verify current directory is still ROOT
```

#### **Common Monorepo Commit Scenarios**

**Single Service Changes:**
```bash
# Work on User Service
cd services/user-service
# ... implement features ...
cd /Users/junseop/Documents/work/taskmate  # ✅ Return to root
git add services/user-service/
git commit -m "feat(user-service): add profile API"
```

**Multi-Service Changes:**
```bash
# Work on multiple services
cd services/user-service && # ... changes ...
cd services/frontend-service && # ... changes ...
cd /Users/junseop/Documents/work/taskmate  # ✅ Return to root
git add services/user-service/ services/frontend-service/
git commit -m "feat: integrate user profile across services"
```

**Documentation + Code Changes:**
```bash
# Implementation + documentation update
cd services/frontend-service && # ... implement UI ...
cd /Users/junseop/Documents/work/taskmate  # ✅ Return to root
git add services/frontend-service/
git add docs/PROJECT_PLAN.md
git commit -m "feat(frontend): complete UI implementation

Phase 4 Frontend 구현 완료
- Rails Views + Tailwind CSS UI 완성
- 모든 백엔드 API 연동 완료
- 반응형 디자인 구현

🧪 테스트 결과: 모든 기능 정상 동작
📊 Phase 4: 100% 완료

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Git Commit Convention

**MANDATORY**: Follow conventional commit format for all commits in this repository.

#### Commit Message Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Commit Types
- **feat**: New feature implementation
- **fix**: Bug fixes
- **docs**: Documentation changes only
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code changes that neither fixes a bug nor adds a feature
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Build process or auxiliary tool changes
- **ci**: CI/CD pipeline changes

#### Scope Examples
- **user-service**: Changes to User Service
- **task-service**: Changes to Task Service  
- **analytics-service**: Changes to Analytics Service
- **file-service**: Changes to File Service
- **docker**: Docker configuration changes
- **k8s**: Kubernetes configuration changes
- **docs**: Documentation updates
- **config**: Configuration file changes

#### Examples (한글 커밋 메시지)
```bash
# 기능 추가
feat(user-service): 사용자 인증 시스템 구현

회원가입, 로그인, 세션 관리 기능 추가
- BCrypt 패스워드 암호화를 사용한 User 모델 추가
- 로그인/로그아웃 엔드포인트를 포함한 AuthController 구현
- 세션 기반 인증 미들웨어 추가
- RSpec 테스트 포함

Closes #123

# 버그 수정
fix(task-service): 태스크 상태 업데이트 검증 오류 해결

'pending'에서 'completed'로의 상태 전환을 막던 검증 로직 수정
- Task 모델 상태 머신 검증 업데이트
- 엣지 케이스에 대한 테스트 케이스 추가

# 문서화
docs: 최적화된 데이터베이스 구성으로 PROJECT_PLAN 업데이트

- 여러 PostgreSQL 인스턴스에서 단일 인스턴스 멀티 DB로 변경
- Phase 1-2 구현 태스크와 예상 시간 상세 추가
- 기술적 결정 사항과 성공 기준 추가
- 개발 워크플로우와 리소스 효율성 개선

# Docker 설정
chore(docker): 멀티 데이터베이스 PostgreSQL 설정 추가

- PostgreSQL과 Redis 서비스를 포함한 docker-compose.yml 추가
- 멀티 데이터베이스 생성 스크립트 작성
- 개발 환경 변수 설정
```

#### Commit Guidelines (한글 사용)
1. **제목 (50자 이내)**:
   - 타입은 영어, 설명은 한글 사용
   - 명령형으로 작성 ("추가", "수정", "삭제" 등)
   - 마침표 없음

2. **본문 (줄당 72자)**:
   - 무엇을 왜 했는지 설명 (어떻게는 생략)
   - 여러 변경사항은 불릿 포인트 사용
   - 복잡한 변경사항은 상세 설명 포함

3. **푸터**:
   - 이슈 참조: `Closes #123`, `Fixes #456`
   - 브레이킹 체인지: `BREAKING CHANGE: 설명`
   - 공동 작성자: `Co-Authored-By: Claude <noreply@anthropic.com>`

#### Commit Guidelines
1. **Subject Line (50 chars max)**:
   - Use imperative mood ("add", not "added" or "adds")
   - No capitalization of first letter after type
   - No period at the end

2. **Body (72 chars per line)**:
   - Explain what and why vs. how
   - Use bullet points for multiple changes
   - Include context for complex changes

3. **Footer**:
   - Reference issues: `Closes #123`, `Fixes #456`
   - Breaking changes: `BREAKING CHANGE: description`
   - Co-authors: `Co-Authored-By: Claude <noreply@anthropic.com>`

4. **Atomic Commits**:
   - One logical change per commit
   - All tests should pass after each commit
   - Commit related files together

## 📋 Commit Checklist

**⚠️ MANDATORY**: Follow this comprehensive checklist before every commit.

### 1. Code Quality Verification
```bash
# Test execution and pass verification
bundle exec rspec
# Verify: 53 examples, 0 failures

# Code style check
bundle exec rubocop
# Verify: no offenses detected

# Coverage check (maintain above 80%)
# Check coverage/index.html
```

### 2. PROJECT_PLAN.md Update

#### Reflect Current Status
- [ ] **Update Phase Progress** (e.g., `70% 진행`)
- [ ] **Mark Completed Items** (`[ ]` → `✅`)
- [ ] **Update Current Status** description
- [ ] **Specify Next Steps** (`← **다음 단계**`)

#### Update Test Status
- [ ] Reflect newly added test count
- [ ] Update total test count (e.g., `53개 모두 통과`)
- [ ] Update code coverage percentage (e.g., `91.75%`)
- [ ] Specify new feature test scope

#### Reflect Implementation Status
- [ ] Add newly implemented API endpoints
- [ ] Mark model/controller implementation complete
- [ ] Reflect security feature implementation
- [ ] Specify development tools/scripts additions

### 3. Documentation Consistency Check

#### API Endpoint Consistency
- [ ] API list in PROJECT_PLAN.md
- [ ] Actual routing in `config/routes.rb`
- [ ] Controller method implementation
- [ ] Test case endpoints

#### Version Information Check
- [ ] Ruby version (3.4.3)
- [ ] Rails version (8.0.2.1)
- [ ] Service port numbers (User: 3000, Task: 3001, Analytics: 3002, File: 3003)
- [ ] Database name consistency

### 4. Docker Configuration Verification
- [ ] All services start with `docker-compose up -d`
- [ ] Health checks pass for PostgreSQL and Redis
- [ ] Service ports are accessible
- [ ] Volume mounts work correctly
- [ ] Environment variables are properly set

## Pre-Commit Testing Protocol

**⚠️ MANDATORY**: Always run tests before committing and ensure they pass.

### Required Testing Steps Before Every Commit

1. **Run All Tests**: Execute complete test suite for affected services
2. **Verify Pass Rate**: Ensure 100% test pass rate (no failures, no errors)
3. **Check Coverage**: Maintain minimum 80% code coverage
4. **Lint Check**: Run code quality checks if available
5. **PROJECT_PLAN Update**: Update docs/PROJECT_PLAN.md to reflect current progress

### Testing Commands by Service

```bash
# Docker-based Testing (Recommended)
# Start infrastructure first
docker-compose up -d postgres redis

# User Service Tests
cd services/user-service
./pre_commit_check.sh  # 자동화된 전체 검증

# 또는 개별 실행
bundle exec rspec      # 테스트 실행
bundle exec rubocop    # 코드 스타일 검사

# Task Service Tests
cd services/task-service  
DATABASE_URL="postgresql://taskmate:password@127.0.0.1:5432/task_service_test_db" RAILS_ENV=test bundle exec rspec

# Analytics Service Tests  
cd services/analytics-service
DATABASE_URL="postgresql://taskmate:password@127.0.0.1:5432/analytics_service_test_db" RAILS_ENV=test bundle exec rspec

# File Service Tests
cd services/file-service  
DATABASE_URL="postgresql://taskmate:password@127.0.0.1:5432/file_service_test_db" RAILS_ENV=test bundle exec rspec

# Full Project Tests
./scripts/test.sh
```

### PROJECT_PLAN.md 업데이트 프로토콜

**모든 기능 구현 후 필수 업데이트:**
1. **완료 상태 반영**: `[ ]` → `✅` 체크박스 변경
2. **진행률 업데이트**: Phase 진행률 퍼센트 수정
3. **테스트 현황**: 새로운 테스트 수, 커버리지 반영
4. **다음 단계**: `← **다음 단계**` 표시 이동
5. **기능 명세**: 새로 구현된 API/기능 추가

### Commit Rejection Criteria

**DO NOT COMMIT** if any of the following occur:
- ❌ Any test failures or errors
- ❌ Coverage drops below 80%
- ❌ Syntax errors or linting failures
- ❌ Database migration issues
- ❌ PROJECT_PLAN.md not updated for feature changes

### Emergency Override

Only in exceptional circumstances (documentation-only changes, infrastructure setup), 
commits may proceed without full testing. Must include `[skip-tests]` in commit message.

Example:
```bash
docs: README 구조 개선 [skip-tests]

순수 문서 변경으로 테스트 영향 없음
```

### Commit Message Protocol

Follow conventional commit format with Korean descriptions:

```bash
<type>(<scope>): <한글 제목>

<한글 상세 설명>
- 주요 변경사항 리스트
- 구현된 기능 설명

🧪 테스트 결과: N개 테스트 모두 통과
📊 커버리지: XX.XX%

Co-Authored-By: Claude <noreply@anthropic.com>
```

## 🚨 Troubleshooting Guide

### 1. Docker Issues

#### Container Startup Failures
```bash
# Check container status
docker-compose ps

# View logs for specific service
docker-compose logs [service-name]

# Restart all services
docker-compose down
docker-compose up -d

# Remove volumes if needed (⚠️ Data Loss)
docker-compose down -v
docker-compose up -d
```

#### Port Conflicts
```bash
# Check what's using a port
lsof -i :3000

# Kill process using port
kill -9 <PID>

# Or kill all Rails servers
pkill -f "rails server"
```

### 2. Database Issues

#### Connection Errors
```bash
# Test PostgreSQL connection
PGPASSWORD=password psql -h 127.0.0.1 -p 5432 -U taskmate -l

# Restart PostgreSQL container
docker-compose restart postgres

# Check database exists
PGPASSWORD=password psql -h 127.0.0.1 -p 5432 -U taskmate -d postgres -c "\l"
```

#### Migration Issues
```bash
# Reset test database
cd services/[service-name]
RAILS_ENV=test rails db:drop
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:migrate

# Check migration status
rails db:migrate:status
```

### 3. Service Communication Issues

#### API Not Responding
```bash
# Check if service is running
curl -v http://localhost:3000/up

# Check Rails logs
tail -f services/user-service/log/development.log

# Verify network connectivity
docker exec taskmate_user_service ping taskmate_postgres
```

#### Authentication Errors
```bash
# Check session cookies
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt -v \
  -d '{"email":"test@example.com","password":"password123"}'

# Verify session in database
PGPASSWORD=password psql -h 127.0.0.1 -p 5432 -U taskmate -d user_service_db \
  -c "SELECT id, user_id, expires_at FROM sessions;"
```

### 4. Development Tools

#### Rails Console Access
```bash
# Inside container
docker exec -it taskmate_user_service rails console

# Or locally (if gems installed)
cd services/user-service
rails console
```

#### Database Direct Access
```bash
# Connect to specific service database
PGPASSWORD=password psql -h 127.0.0.1 -p 5432 -U taskmate -d user_service_db

# List all tables
\dt

# Check users
SELECT id, name, email, created_at FROM users;
```

## Important Notes

- This is a graduation project for demonstration purposes
- Local development and testing only (no production deployment)
- All services use Rails 8 with session-based authentication
- Focus on microservices architecture patterns and Kubernetes deployment