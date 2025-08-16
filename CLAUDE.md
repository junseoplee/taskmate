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

## Important Notes

- This is a graduation project for demonstration purposes
- Local development and testing only (no production deployment)
- All services use Rails 8 with session-based authentication
- Focus on microservices architecture patterns and Kubernetes deployment