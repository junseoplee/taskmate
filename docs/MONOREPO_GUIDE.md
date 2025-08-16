# TaskMate 모노레포 가이드

## 📁 모노레포 구조 개요

TaskMate는 4개의 독립적인 Ruby on Rails 마이크로서비스를 하나의 모노레포에서 관리합니다.

```
taskmate/ (모노레포 루트)
├── services/                    # 마이크로서비스들
│   ├── user-service/           # 포트 3000 - 인증 & 사용자 관리
│   ├── task-service/           # 포트 3001 - 태스크 CRUD
│   ├── analytics-service/      # 포트 3002 - 통계 & 대시보드
│   └── file-service/          # 포트 3003 - 파일 첨부
├── k8s/                       # Kubernetes 설정
├── docker/                    # Docker 설정
├── docs/                      # 공통 문서
├── docker-compose.yml         # 공유 인프라 (DB, Redis)
└── README.md                  # 프로젝트 개요
```

## 🏗️ 각 서비스 구조

### User Service (포트 3000)
```
services/user-service/
├── app/
│   ├── controllers/api/v1/     # API 컨트롤러
│   └── models/                 # User, Session 모델
├── config/
│   ├── database.yml           # user_service_db 연결
│   └── routes.rb              # /api/v1/auth/* 라우팅
├── db/migrate/                # 독립적인 마이그레이션
├── spec/                      # RSpec 테스트
├── Gemfile                    # 독립적인 의존성
└── test_api.sh               # API 테스트 스크립트
```

### 각 서비스는 완전히 독립적
- ✅ 각자의 Gemfile과 의존성 관리
- ✅ 독립적인 데이터베이스 (멀티 DB 구조)
- ✅ 별도 포트에서 실행
- ✅ 독립적인 테스트 슈트
- ✅ 개별 배포 가능

## 🔧 포트 관리 전략

### 포트 할당 체계
| 서비스 | 포트 | 역할 | 상태 |
|--------|------|------|------|
| User Service | 3000 | 인증 & 세션 관리 | ✅ 구현완료 |
| Task Service | 3001 | 태스크 CRUD | 🚧 예정 |
| Analytics Service | 3002 | 통계 & 대시보드 | 🚧 예정 |
| File Service | 3003 | 파일 첨부 | 🚧 예정 |

### 공유 인프라
| 서비스 | 포트 | 용도 |
|--------|------|------|
| PostgreSQL | 5432 | 모든 서비스 데이터베이스 |
| Redis | 6379 | 캐시 & 세션 스토어 |

## ⚙️ 개발 환경 관리

### 1. 전체 인프라 시작
```bash
# 루트 디렉토리에서
docker-compose up -d

# 확인
docker-compose ps
```

### 2. 개별 서비스 실행
```bash
# User Service
cd services/user-service
rails server -p 3000

# Task Service (미래)
cd services/task-service  
rails server -p 3001

# Analytics Service (미래)
cd services/analytics-service
rails server -p 3002

# File Service (미래)
cd services/file-service
rails server -p 3003
```

### 3. 동시 실행 관리
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

## 🗄️ 데이터베이스 구조

### 멀티 데이터베이스 전략
```
PostgreSQL (단일 인스턴스)
├── user_service_db           # User, Session 테이블
├── task_service_db          # Task, Project 테이블
├── analytics_service_db     # Analytics 테이블  
└── file_service_db          # File, Attachment 테이블
```

### 각 서비스의 database.yml
```yaml
development:
  adapter: postgresql
  database: user_service_db    # 서비스별로 다름
  username: taskmate
  password: password
  host: localhost
  port: 5432
```

## 🔄 서비스 간 통신

### 1. 동기 통신 (REST API)
```bash
# User Service → Task Service
curl http://localhost:3001/api/v1/tasks \
  -H "Cookie: session_token=abc123"

# Task Service에서 User 검증
curl http://localhost:3000/api/v1/auth/verify \
  -H "Cookie: session_token=abc123"
```

### 2. 비동기 통신 (Redis 이벤트)
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

## 🚀 배포 전략

### 1. 개발 환경
- 각 서비스를 개별 포트에서 실행
- 공유 PostgreSQL/Redis 사용

### 2. Kubernetes 환경 (미래)
- 각 서비스를 별도 Pod로 배포
- Service Mesh로 통신 관리
- 개별 스케일링 가능

## ⚠️ 주의사항 및 모범 사례

### 포트 충돌 방지
```bash
# 포트 사용 확인
lsof -i :3000
lsof -i :3001
lsof -i :3002
lsof -i :3003

# 프로세스 종료
kill -9 <PID>
```

### Ruby 버전 관리
```bash
# 모든 서비스는 동일한 Ruby 버전 사용
ruby -v
# ruby 3.4.3

# rbenv로 버전 고정
echo "3.4.3" > .ruby-version
```

### 의존성 충돌 방지
- 각 서비스는 독립적인 Gemfile
- 공통 gem 버전은 가능한 맞춤
- bundle install은 각 서비스 디렉토리에서 실행

### 테스트 격리
```bash
# 각 서비스 테스트는 독립적으로 실행
cd services/user-service && bundle exec rspec
cd services/task-service && bundle exec rspec

# 전체 테스트 (미래 스크립트)
./test_all_services.sh
```

## 🔍 모니터링 및 디버깅

### 로그 확인
```bash
# 각 서비스 로그
tail -f services/user-service/log/development.log
tail -f services/task-service/log/development.log

# Docker 서비스 로그
docker-compose logs postgres
docker-compose logs redis
```

### 상태 확인
```bash
# 모든 서비스 헬스체크
curl http://localhost:3000/up  # User Service
curl http://localhost:3001/up  # Task Service
curl http://localhost:3002/up  # Analytics Service
curl http://localhost:3003/up  # File Service

# 데이터베이스 연결 확인
psql -h localhost -U taskmate -l
```

## 🎯 개발 워크플로우

### 1. 새로운 기능 개발
1. 해당 서비스 디렉토리로 이동
2. 기능별 브랜치 생성
3. TDD로 개발
4. 개별 서비스 테스트
5. 서비스 간 통합 테스트
6. PR 생성

### 2. 서비스 간 API 계약
- OpenAPI 스펙 문서 작성
- API 버전 관리 (/api/v1/)
- 하위 호환성 유지

### 3. 데이터 일관성
- 각 서비스는 자신의 데이터만 소유
- 서비스 간 데이터 공유는 API 통신으로만
- Eventually Consistent 모델 적용

이 구조를 통해 각 서비스는 독립적으로 개발, 테스트, 배포할 수 있으면서도 하나의 통합된 애플리케이션으로 동작할 수 있습니다.