# TaskMate 개발 가이드

TaskMate 프로젝트의 개발 환경 설정 및 API 테스트 방법을 안내합니다.

## 🚀 빠른 시작

### 1. 전체 시스템 시작
```bash
# 1. 프로젝트 루트로 이동
cd /path/to/taskmate

# 2. 공유 인프라 시작 (PostgreSQL, Redis)
docker-compose up -d

# 3. User Service 시작
cd services/user-service
rails server -p 3000
```

### 2. API 동작 확인
```bash
# 새 터미널에서
cd services/user-service
./test_api.sh
```

## 📋 단계별 개발 환경 설정

### Step 1: 시스템 요구사항 확인
```bash
# Ruby 버전 확인
ruby -v
# 출력: ruby 3.4.3

# Rails 버전 확인  
cd services/user-service
rails -v
# 출력: Rails 8.0.2.1

# Docker 확인
docker --version
docker-compose --version
```

### Step 2: 데이터베이스 설정
```bash
# 1. Docker 서비스 시작
docker-compose up -d

# 2. 서비스 상태 확인
docker-compose ps
# STATUS가 "Up" 및 "healthy"인지 확인

# 3. 데이터베이스 생성 및 마이그레이션
cd services/user-service
rails db:create
rails db:migrate

# 4. 테스트 데이터베이스 설정
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:migrate
```

### Step 3: 의존성 설치
```bash
cd services/user-service
bundle install
```

## 🧪 테스트 실행 방법

### 1. 자동화된 테스트 (RSpec)
```bash
cd services/user-service

# 전체 테스트 실행
bundle exec rspec

# 특정 파일 테스트
bundle exec rspec spec/models/user_spec.rb
bundle exec rspec spec/controllers/api/v1/auth_controller_spec.rb

# 커버리지 포함 테스트
bundle exec rspec --format documentation
```

**예상 결과:**
```
53 examples, 0 failures
Line Coverage: 91.75% (89 / 97)
```

### 2. 코드 품질 검사
```bash
# Rubocop 검사
bundle exec rubocop

# 자동 수정
bundle exec rubocop -A
```

### 3. 수동 API 테스트

#### A. 자동화 스크립트 사용
```bash
cd services/user-service
./test_api.sh
```

#### B. 개별 API 테스트

**1) 서버 시작**
```bash
# 터미널 1
cd services/user-service
rails server -p 3000

# 서버 시작 확인 (터미널 2)
curl http://localhost:3000/up
```

**2) 회원가입 테스트**
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{
    "name": "홍길동",
    "email": "hong@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

**예상 응답:**
```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "홍길동",
    "email": "hong@example.com",
    "created_at": "2025-08-16T12:00:00.000Z"
  }
}
```

**3) 로그인 테스트**
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{
    "email": "hong@example.com",
    "password": "password123"
  }'
```

**4) 세션 검증 테스트**
```bash
curl -X GET http://localhost:3000/api/v1/auth/verify \
  -H "Content-Type: application/json" \
  -b cookies.txt
```

**5) 로그아웃 테스트**
```bash
curl -X POST http://localhost:3000/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -b cookies.txt
```

## 🔧 개발 도구 및 팁

### 1. Rails 콘솔 사용
```bash
cd services/user-service
rails console

# 콘솔에서 사용자 생성 테스트
user = User.create!(
  name: "테스트 유저",
  email: "test@example.com",
  password: "password123",
  password_confirmation: "password123"
)

# 세션 생성 테스트
session = user.sessions.create!
puts session.token
```

### 2. 데이터베이스 직접 접근
```bash
# PostgreSQL 콘솔 접근
psql -h localhost -U taskmate -d user_service_db

# 테이블 확인
\dt

# 사용자 데이터 확인
SELECT id, name, email, created_at FROM users;

# 세션 데이터 확인
SELECT id, user_id, expires_at, created_at FROM sessions;
```

### 3. 로그 모니터링
```bash
# 개발 로그 실시간 모니터링
tail -f services/user-service/log/development.log

# 테스트 로그 확인
tail -f services/user-service/log/test.log
```

## 🚨 문제 해결 가이드

### 1. 서버 시작 실패
```bash
# 포트 충돌 확인
lsof -i :3000

# 기존 프로세스 종료
kill -9 <PID>

# 또는 모든 Rails 서버 종료
pkill -f "rails server"
```

### 2. 데이터베이스 연결 오류
```bash
# Docker 서비스 재시작
docker-compose down
docker-compose up -d

# 연결 테스트
psql -h localhost -U taskmate -l
```

### 3. 테스트 실패
```bash
# 테스트 데이터베이스 리셋
RAILS_ENV=test rails db:drop
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:migrate

# 캐시 클리어
rails tmp:clear
```

### 4. API 응답 없음
```bash
# 서버 상태 확인
ps aux | grep rails

# 로그 확인
tail -f log/development.log

# 방화벽/네트워크 확인
curl -v http://localhost:3000/up
```

## 📊 성능 모니터링

### 1. 응답 시간 측정
```bash
# curl을 사용한 응답 시간 측정
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:3000/api/v1/auth/verify

# curl-format.txt 파일 내용:
#     time_namelookup:  %{time_namelookup}\n
#        time_connect:  %{time_connect}\n
#     time_appconnect:  %{time_appconnect}\n
#    time_pretransfer:  %{time_pretransfer}\n
#       time_redirect:  %{time_redirect}\n
#  time_starttransfer:  %{time_starttransfer}\n
#                     ----------\n
#          time_total:  %{time_total}\n
```

### 2. 메모리 사용량 확인
```bash
# Rails 서버 메모리 사용량
ps aux | grep rails | grep -v grep

# 전체 시스템 리소스
top -p $(pgrep -f "rails server")
```

## 🔄 CI/CD 연동

### GitHub Actions에서 테스트
```yaml
# .github/workflows/user-service.yml 예시
name: User Service CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: password
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
    - uses: actions/checkout@v3
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: 3.4.3
        bundler-cache: true
        working-directory: services/user-service
    
    - name: Run tests
      working-directory: services/user-service
      run: |
        bundle exec rspec
        bundle exec rubocop
```

## 📝 개발 체크리스트

### 새 기능 개발 시
- [ ] TDD로 테스트 먼저 작성
- [ ] 기능 구현
- [ ] 모든 테스트 통과 확인
- [ ] Rubocop 검사 통과
- [ ] API 수동 테스트
- [ ] 커버리지 80% 이상 유지
- [ ] 커밋 전 테스트 재실행

### 커밋 전 체크리스트
```bash
# 1. 전체 테스트
bundle exec rspec

# 2. 코드 품질
bundle exec rubocop

# 3. API 동작 확인
./test_api.sh

# 4. 모든 항목 통과 시 커밋
git add .
git commit -m "feat: 새로운 기능 추가"
```

이 가이드를 따라하시면 TaskMate User Service의 모든 기능을 안전하게 테스트하고 개발할 수 있습니다!