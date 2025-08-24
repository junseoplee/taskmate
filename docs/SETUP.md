# TaskMate Setup Guide

TaskMate 마이크로서비스 아키텍처 개발 환경 설정 가이드입니다.

## 📋 Prerequisites

### 필수 요구사항
- **Docker** 20.10+ and **Docker Compose** 2.0+
- **Git** 2.30+
- **minikube** (Kubernetes 환경용, 선택사항)
- **kubectl** (Kubernetes 환경용, 선택사항)

### 권장 사항
- Ruby 3.4.3 (로컬 개발 및 테스트용)
- PostgreSQL 클라이언트 (데이터베이스 접근용)

## 🚀 Quick Start

### 1단계: 저장소 클론
```bash
git clone <repository-url>
cd taskmate

# 프로젝트 구조 확인
ls -la
# services/   - 5개 마이크로서비스 (User, Task, Analytics, File, Frontend)
# k8s/        - Kubernetes 매니페스트
# docs/       - 프로젝트 문서
# scripts/    - 개발 스크립트
```

### 2단계: Docker Compose 환경 시작
```bash
# 모든 서비스 시작 (PostgreSQL, Redis, 5개 마이크로서비스)
docker-compose up -d

# 서비스 상태 확인
docker-compose ps
```

### 3단계: 서비스 접근 확인
```bash
# User Service (포트 3000)
curl http://localhost:3000/up

# Task Service (포트 3001) 
curl http://localhost:3001/up

# Analytics Service (포트 3002)
curl http://localhost:3002/up

# File Service (포트 3003)
curl http://localhost:3003/up

# Frontend Service (포트 3100)
curl http://localhost:3100/up
```

## 🔧 Development Workflow

### 서비스 시작

```bash
# 인프라만 시작 (PostgreSQL + Redis)
docker-compose up -d postgres redis

# 모든 서비스 시작
docker-compose up -d

# 로그와 함께 시작 (개발용)
docker-compose up

# 특정 서비스만 시작
docker-compose up -d user-service task-service
```

### 서비스 빌드

```bash
# 모든 서비스 이미지 재빌드
docker-compose build

# 특정 서비스만 재빌드
docker-compose build user-service

# 캐시 없이 완전 재빌드
docker-compose build --no-cache
```

### 테스트 실행

```bash
# User Service 테스트
cd services/user-service
bundle exec rspec

# Task Service 테스트
cd services/task-service
bundle exec rspec

# File Service 테스트
cd services/file-service
bundle exec rspec

# Docker 컨테이너 내에서 테스트
docker-compose exec user-service bundle exec rspec
```

### 서비스 중지

```bash
# 모든 서비스 중지
docker-compose down

# 볼륨까지 삭제 (데이터 완전 삭제)
docker-compose down -v

# 이미지까지 삭제
docker-compose down --rmi all
```

## 🌐 Service URLs

### 백엔드 마이크로서비스
- **User Service**: http://localhost:3000
  - 인증 API: `/api/v1/auth/*`
  - 헬스체크: `/up`
- **Task Service**: http://localhost:3001
  - 태스크 API: `/api/v1/tasks/*`
  - 헬스체크: `/up`
- **Analytics Service**: http://localhost:3002 ⚠️
  - 통계 API: `/api/v1/analytics/*` ❌ **구현 필요**
  - 헬스체크: `/up`
- **File Service**: http://localhost:3003
  - 파일 API: `/api/v1/file_*`
  - 헬스체크: `/up`

### 프론트엔드 서비스
- **Frontend Service**: http://localhost:3100 🔄
  - Web UI: 메인 웹 애플리케이션
  - API Gateway: 백엔드 서비스 프록시
  - 헬스체크: `/up`

### 인프라
- **PostgreSQL**: localhost:5432
  - 사용자: `taskmate`
  - 패스워드: `password`
  - 데이터베이스: `user_service_db`, `task_service_db`, `analytics_service_db`, `file_service_db`
  - Frontend Service는 데이터베이스 없음 (API Gateway 패턴)
- **Redis**: localhost:6379
  - 세션 관리 및 캐싱용

## 🗄️ Database Access

### PostgreSQL 접근

```bash
# User Service DB 접근
docker-compose exec postgres psql -U taskmate -d user_service_db

# Task Service DB 접근
docker-compose exec postgres psql -U taskmate -d task_service_db

# Analytics Service DB 접근
docker-compose exec postgres psql -U taskmate -d analytics_service_db

# File Service DB 접근
docker-compose exec postgres psql -U taskmate -d file_service_db

# 모든 데이터베이스 목록 확인
docker-compose exec postgres psql -U taskmate -d postgres -c "\l"

# 특정 DB의 테이블 목록 확인
docker-compose exec postgres psql -U taskmate -d user_service_db -c "\dt"
```

### Redis 접근

```bash
# Redis CLI 접근
docker-compose exec redis redis-cli

# 모든 키 확인
docker-compose exec redis redis-cli KEYS '*'

# 세션 정보 확인
docker-compose exec redis redis-cli GET session:*
```

### 데이터베이스 마이그레이션

```bash
# User Service 마이그레이션
docker-compose exec user-service ./bin/rails db:migrate

# Task Service 마이그레이션
docker-compose exec task-service ./bin/rails db:migrate

# Analytics Service 마이그레이션
docker-compose exec analytics-service ./bin/rails db:migrate

# File Service 마이그레이션
docker-compose exec file-service ./bin/rails db:migrate

# Frontend Service (마이그레이션 없음 - API Gateway)
# docker-compose exec frontend-service ./bin/rails db:migrate  # 불필요
```

## 🔍 Troubleshooting

### 일반적인 문제들

#### 1. 포트 충돌 문제
```bash
# 포트 사용 프로세스 확인
lsof -i :3000
lsof -i :3001
lsof -i :5432

# 프로세스 종료
kill -9 <PID>

# Docker 컨테이너 정리
docker-compose down
docker system prune -f
```

#### 2. 데이터베이스 연결 실패
```bash
# PostgreSQL 로그 확인
docker-compose logs postgres

# PostgreSQL 컨테이너 재시작
docker-compose restart postgres

# 데이터베이스 연결 테스트
docker-compose exec postgres pg_isready -U taskmate

# 데이터베이스 완전 재생성
docker-compose down -v
docker-compose up -d postgres
```

#### 3. 서비스 시작 실패
```bash
# 모든 컨테이너 로그 확인
docker-compose logs

# 특정 서비스 로그 확인
docker-compose logs user-service
docker-compose logs task-service
docker-compose logs analytics-service
docker-compose logs file-service
docker-compose logs frontend-service

# 컨테이너 상태 확인
docker-compose ps

# 완전 재시작
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

#### 4. Rails 애플리케이션 오류
```bash
# Rails 서버 로그 확인
docker-compose logs -f user-service

# 컨테이너 내부 접근
docker-compose exec user-service bash

# 수동으로 Rails 서버 시작
docker-compose exec user-service ./bin/rails server -b 0.0.0.0 -p 3000

# Gemfile 의존성 재설치
docker-compose exec user-service bundle install
```

### 로그 모니터링

```bash
# 모든 서비스 로그 실시간 모니터링
docker-compose logs -f

# 특정 서비스 로그 실시간 모니터링
docker-compose logs -f user-service
docker-compose logs -f task-service
docker-compose logs -f analytics-service
docker-compose logs -f file-service
docker-compose logs -f frontend-service
docker-compose logs -f postgres
docker-compose logs -f redis

# 최근 로그만 확인 (마지막 100줄)
docker-compose logs --tail=100 user-service
```

### 성능 모니터링

```bash
# 컨테이너 리소스 사용량 확인
docker stats

# 특정 컨테이너 리소스 확인
docker stats taskmate_user_service taskmate_postgres

# 디스크 사용량 확인
docker system df

# 볼륨 사용량 확인
docker volume ls
```

## 💡 Development Tips

### 개발 효율성 팁

- **환경 변수**: `.env` 파일에서 환경 설정 관리
- **볼륨 마운트**: 소스 코드 변경사항이 즉시 반영됨
- **헬스체크**: 각 서비스의 `/up` 또는 `/health` 엔드포인트로 상태 확인
- **데이터 지속성**: PostgreSQL과 Redis 데이터는 Docker 볼륨에 저장됨

### API 테스트 스크립트

```bash
# 회원가입 테스트
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "name": "Test User",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'

# 로그인 테스트
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123"
    }
  }'

# 태스크 생성 테스트
curl -X POST http://localhost:3001/api/v1/tasks \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "task": {
      "title": "Test Task",
      "description": "Test Description",
      "priority": "medium"
    }
  }'

# 파일 카테고리 조회
curl -b cookies.txt http://localhost:3003/api/v1/file_categories

# Frontend 서비스 접속 테스트 (브라우저에서 확인)
open http://localhost:3100
# 또는
curl http://localhost:3100
```

### 개발 워크플로우

1. **기능 개발**: 로컬에서 코드 수정
2. **테스트**: `bundle exec rspec` 또는 Docker 내에서 테스트
3. **통합 테스트**: 전체 서비스 간 API 호출 테스트
4. **커밋**: TDD 사이클 완료 후 커밋

### 현재 구현 상태 및 주의사항

#### ✅ 완전 구현된 서비스
- **User Service**: 인증/세션 API 완전 구현 (53개 테스트)
- **Task Service**: 태스크 CRUD API 완전 구현 (39개 테스트)
- **File Service**: 파일 관리 API 완전 구현 (TDD 완료)

#### ⚠️ 부분 구현된 서비스
- **Analytics Service**: 기본 구조만 완료
  - ❌ 통계 API 미구현 (`/api/v1/analytics/dashboard`, `/api/v1/analytics/tasks/completion-rate`, `/api/v1/analytics/priority-distribution`)
  - ✅ 헬스체크 API만 구현됨

#### 🔄 진행중인 서비스
- **Frontend Service**: 40% 구현 완료
  - ✅ 컨트롤러 및 Service Client 구현
  - ❌ 뷰 템플릿 및 UI 구현 필요
  - ⚠️ 한글 인코딩 문제 수정 필요

### Kubernetes 환경

```bash
# minikube 시작
minikube start

# Kubernetes 배포 (구현 예정)
kubectl apply -f k8s/

# 서비스 접근
kubectl port-forward service/user-service 3000:3000
```