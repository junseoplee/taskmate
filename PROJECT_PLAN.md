# TaskMate 프로젝트 개발 계획서

## 프로젝트 개요
**TaskMate**는 Ruby on Rails 8 기반의 마이크로서비스 아키텍처(MSA)로 구현되는 할일 관리 애플리케이션입니다. 4개의 독립적인 서비스로 구성되며, Kubernetes 환경(minikube)에서 실행됩니다.

## 기술 스택

### Backend
- **Framework**: Ruby on Rails 8
- **Database**: PostgreSQL (서비스별 독립 DB)
- **Cache**: Redis (세션 관리)
- **Authentication**: Rails 8 내장 세션 기반 인증

### Frontend  
- **View**: Rails Views (ERB)
- **CSS**: Tailwind CSS
- **JavaScript**: Turbo + Stimulus

### Infrastructure
- **Container**: Docker
- **Orchestration**: Kubernetes (minikube)
- **Gateway**: NGINX Ingress
- **Monitoring**: Prometheus + Grafana

## 마이크로서비스 구성

### 공유 인프라
- **PostgreSQL**: 포트 5432 (멀티 데이터베이스)
- **Redis**: 포트 6379 (세션 관리)

### 1. User Service (포트 3000)
- **데이터베이스**: user_service_db
- 사용자 인증/인가
- 세션 관리
- 프로필 관리
- 다른 서비스의 인증 검증 API 제공

### 2. Task Service (포트 3001)
- **데이터베이스**: task_service_db
- 할일 CRUD
- 상태 관리 (진행중/완료/보류)
- 우선순위 및 마감일 관리

### 3. Analytics Service (포트 3002)
- **데이터베이스**: analytics_service_db
- 통계 데이터 집계
- 완료율/진행률 계산
- 대시보드 데이터 제공

### 4. File Service (포트 3003)
- **데이터베이스**: file_service_db
- 파일 업로드/다운로드
- 파일 메타데이터 관리
- 태스크별 첨부파일 관리

## 개발 페이즈

### ✅ 완료된 작업
- Ruby 3.4.3 및 Rails 8 프로젝트 초기화 완료
- PostgreSQL, Tailwind CSS 설정 완료
- 프로젝트 문서화 (README, PROJECT_PLAN, CLAUDE.md) 완료
- GitHub 저장소 설정 및 이니셜 커밋 완료

### Phase 1: 프로젝트 초기 설정 (진행 중)
**예상 소요시간**: 1일  
**우선순위**: HIGH

#### 1.1 Docker 환경 구성 (2-3시간)
- [ ] 루트 레벨 `docker-compose.yml` 생성
  - PostgreSQL 서비스 설정 (포트 5432, 멀티 DB 지원)
  - Redis 서비스 설정 (포트 6379)
  - 각 마이크로서비스용 컨테이너 정의
- [ ] 멀티 데이터베이스 생성 스크립트 작성
  - `scripts/create-multiple-postgresql-databases.sh`
- [ ] 개발용 `Dockerfile.dev` 생성
- [ ] `.env.example` 파일 생성 (DB 연결 정보, API 키 등)
- [ ] Docker 네트워크 설정 (서비스 간 통신)

#### 1.2 프로젝트 디렉토리 구조 생성 (30분)
```bash
services/
├── user-service/      # 포트 3000
├── task-service/      # 포트 3001
├── analytics-service/ # 포트 3002
└── file-service/      # 포트 3003
k8s/
├── deployments/
├── services/
├── ingress/
└── configmaps/
docker/
├── development/
└── production/
docs/
├── api/
├── architecture/
└── deployment/
```

#### 1.3 개발 환경 스크립트 작성 (1시간)
- [ ] `scripts/setup.sh` - 초기 환경 설정
- [ ] `scripts/dev.sh` - 개발 서버 실행
- [ ] `scripts/test.sh` - 테스트 실행
- [ ] `scripts/build.sh` - Docker 이미지 빌드

### Phase 2: 핵심 서비스 개발 (User + Task)
**예상 소요시간**: 1-2주  
**우선순위**: HIGH  
**의존성**: Phase 1 완료

#### 2.1 User Service 개발 (3-4일)
**포트**: 3000, **DB**: user_service_db (공유 PostgreSQL)

**2.1.1 프로젝트 구조 생성**
```bash
cd services/user-service
rails new . --api --database=postgresql --skip-test
```

**2.1.2 인증 시스템 구현**
- [ ] User 모델 생성
  - `email`, `password_digest`, `name`, `created_at`, `updated_at`
  - BCrypt 패스워드 암호화
  - 이메일 유효성 검증
- [ ] Session 모델 생성
  - `user_id`, `token`, `expires_at`, `created_at`
  - 자동 만료 처리
- [ ] AuthController 생성
  - `POST /auth/login` - 로그인 (세션 생성)
  - `POST /auth/logout` - 로그아웃 (세션 삭제)
  - `POST /auth/register` - 회원가입
  - `GET /auth/verify` - 세션 검증 API (다른 서비스용)

**2.1.3 API 엔드포인트 구현**
- [ ] UsersController 생성
  - `GET /users/profile` - 프로필 조회
  - `PUT /users/profile` - 프로필 수정
- [ ] 인증 미들웨어 구현
- [ ] CORS 설정 (다른 서비스 호출 허용)
- [ ] API 응답 형식 표준화

**2.1.4 데이터베이스 및 환경 설정**
- [ ] `database.yml` 설정 (database: user_service_db, host: localhost, port: 5432)
- [ ] 마이그레이션 실행
- [ ] Seeds 데이터 생성 (테스트 사용자)
- [ ] 환경변수 설정

#### 2.2 Task Service 개발 (3-4일)
**포트**: 3001, **DB**: task_service_db (공유 PostgreSQL)

**2.2.1 프로젝트 구조 생성**
```bash
cd services/task-service
rails new . --api --database=postgresql --skip-test
```

**2.2.2 Task 모델 및 컨트롤러 구현**
- [ ] Task 모델 생성
  - `title`, `description`, `status`, `priority`, `due_date`, `user_id`
  - 상태: `pending`, `in_progress`, `completed`, `cancelled`
  - 우선순위: `low`, `medium`, `high`, `urgent`
  - 유효성 검증 및 비즈니스 로직
- [ ] TasksController 생성
  - `GET /tasks` - 태스크 목록 조회 (user_id 필터링)
  - `POST /tasks` - 태스크 생성
  - `GET /tasks/:id` - 태스크 상세 조회
  - `PUT /tasks/:id` - 태스크 수정
  - `DELETE /tasks/:id` - 태스크 삭제
  - `PATCH /tasks/:id/status` - 태스크 상태 변경

**2.2.3 User Service 연동**
- [ ] HTTParty gem 추가
- [ ] AuthService 클래스 생성 (User Service API 호출)
- [ ] 인증 미들웨어 구현
- [ ] 에러 핸들링 (User Service 연결 실패, 토큰 만료 등)
- [ ] 서비스 헬스 체크

**2.2.4 데이터베이스 및 환경 설정**
- [ ] `database.yml` 설정 (database: task_service_db, host: localhost, port: 5432)
- [ ] 마이그레이션 실행
- [ ] Seeds 데이터 생성 (테스트 태스크)
- [ ] 환경변수 설정

#### 2.3 서비스 간 통신 구현 (2일)
- [ ] API 클라이언트 라이브러리 생성
- [ ] 서비스 간 인증 토큰 전달 로직
- [ ] 네트워크 에러 핸들링 및 재시도 로직
- [ ] 서비스 헬스 체크 엔드포인트 (`/health`)
- [ ] 로깅 시스템 구성 (구조화된 로그)
- [ ] API 문서화 (Swagger/OpenAPI)

#### 2.4 통합 테스트 및 검증 (1-2일)
- [ ] RSpec 설정 (각 서비스)
- [ ] 단위 테스트 작성
  - User 모델 테스트 (인증, 유효성 검증)
  - Task 모델 테스트 (상태 변경, 비즈니스 로직)
  - 컨트롤러 테스트 (API 응답, 에러 처리)
- [ ] 통합 테스트 작성
  - 회원가입 → 로그인 → 태스크 생성 플로우
  - 세션 검증 → 태스크 조회 플로우
  - 서비스 간 통신 테스트
- [ ] 성능 테스트 기본 설정

### Phase 3: 확장 서비스 개발 (Analytics + File)
**태스크:**
- [ ] Analytics Service 구현
  - [ ] Rails 프로젝트 생성
  - [ ] 통계 모델 설계
  - [ ] 이벤트 수신 시스템
  - [ ] 대시보드 API
- [ ] File Service 구현
  - [ ] Rails 프로젝트 생성
  - [ ] Active Storage 설정
  - [ ] 파일 업로드/다운로드 API
  - [ ] 파일 메타데이터 관리
- [ ] 이벤트 기반 통신 구현
- [ ] 서비스 통합 테스트

### Phase 4: Frontend 개발
**태스크:**
- [ ] 기본 레이아웃 구성
- [ ] Tailwind CSS 설정
- [ ] 로그인/회원가입 페이지
- [ ] 대시보드 페이지
- [ ] 태스크 관리 인터페이스
- [ ] 파일 업로드 컴포넌트
- [ ] 통계 차트 구현
- [ ] Turbo/Stimulus 인터랙션

### Phase 5: Kubernetes 배포
**태스크:**
- [ ] Docker 이미지 빌드
  - [ ] 각 서비스별 Dockerfile 작성
  - [ ] 멀티스테이지 빌드 최적화
- [ ] Kubernetes 매니페스트 작성
  - [ ] Deployment 설정
  - [ ] Service 설정
  - [ ] ConfigMap/Secret 설정
- [ ] minikube 클러스터 구성
- [ ] NGINX Ingress 설정
- [ ] 서비스 디스커버리 구성
- [ ] 로드 밸런싱 설정

### Phase 6: 모니터링 및 운영
**태스크:**
- [ ] Prometheus 설정
- [ ] Grafana 대시보드 구성
- [ ] 로깅 시스템 구축
- [ ] Health Check 구현
- [ ] Circuit Breaker 패턴 적용
- [ ] 자동 스케일링 설정 (HPA)

### Phase 7: 테스트 및 최적화
**태스크:**
- [ ] 단위 테스트 작성
- [ ] 통합 테스트 작성
- [ ] 부하 테스트 수행
- [ ] 성능 최적화
- [ ] 보안 점검
- [ ] 코드 리팩토링

### Phase 8: 문서화 및 마무리
**태스크:**
- [ ] API 문서화
- [ ] 아키텍처 다이어그램 작성
- [ ] 사용자 매뉴얼 작성
- [ ] 배포 가이드 작성
- [ ] 프레젠테이션 자료 준비
- [ ] 시연 시나리오 작성

## 주요 기능 구현 플로우

### 1. 로그인 플로우
```
사용자 → User Service → 세션 생성 → 쿠키 설정 → 메인 페이지
```

### 2. 태스크 생성 플로우
```
사용자 → Task Service → User Service(인증) → DB 저장 → Analytics Service(이벤트) → 응답
```

### 3. 파일 첨부 플로우
```
사용자 → File Service → User Service(인증) → 파일 저장 → Task Service(연결) → 응답
```

### 4. 통계 조회 플로우
```
사용자 → Analytics Service → User Service(인증) → 데이터 집계 → 차트 렌더링
```

## 서비스 간 통신 패턴

### 동기 통신 (REST API)
- 브라우저 ↔ 각 서비스
- 서비스 → User Service (인증 검증)
- Task Service ↔ File Service

### 비동기 통신 (이벤트)
- Task Service → Analytics Service
- 모든 서비스 → Analytics Service (통계 업데이트)

## 개발 우선순위 및 일정

### 🚀 Week 1: 핵심 인프라 구축
1. **Phase 1 완료**: Docker 환경 구성 (1일)
2. **Phase 2 시작**: User Service 기본 구조 (2일)
3. **인증 시스템** 구현 (2일)

### 🏗️ Week 2: 서비스 연동
1. **Task Service** 기본 구조 (2일)
2. **User-Task 서비스** 연동 (2일)
3. **통합 테스트** 및 검증 (1일)

### 📈 Week 3: 확장 서비스 준비
1. **Analytics Service** 설계 완료 (2일)
2. **File Service** 설계 완료 (2일)
3. **Phase 2 검증** 및 문서화 (1일)

### 우선순위 분류

1. **필수 기능** (Phase 1-2) - Week 1-2
   - Docker 환경 구성
   - 사용자 인증 및 세션 관리
   - 기본 태스크 CRUD
   - 서비스 간 통신

2. **핵심 기능** (Phase 3-4) - Week 3-4
   - Analytics 및 File Service
   - Frontend UI/UX
   - 통계/대시보드

3. **고급 기능** (Phase 5-8) - Week 5-8
   - Kubernetes 배포
   - 모니터링 시스템
   - 성능 최적화
   - 문서화 및 시연 준비

## 기술적 의사결정 사항

### 즉시 결정 필요
- [ ] API 버전 관리 전략 (`/api/v1/`)
- [ ] 에러 응답 형식 표준화 (JSON 구조)
- [ ] 로깅 포맷 통일 (구조화된 JSON 로그)
- [ ] 환경변수 관리 방식 (dotenv vs Docker secrets)

### 향후 검토 필요
- [ ] 서비스 간 인증 방식 (Session token 전달 방식)
- [ ] 데이터베이스 마이그레이션 전략
- [ ] 모니터링 도구 선택 (Prometheus + Grafana)
- [ ] CI/CD 파이프라인 구축

## 성공 지표 및 검증 방법

### Phase 1 완료 기준
- [ ] `docker-compose up`으로 모든 서비스 실행 가능
- [ ] 개발 스크립트 (`scripts/dev.sh`) 동작 확인
- [ ] PostgreSQL, Redis 연결 확인

### Phase 2 완료 기준
- [ ] 회원가입/로그인 API 정상 동작
- [ ] 태스크 CRUD API 정상 동작
- [ ] 서비스 간 인증 검증 정상 동작
- [ ] 통합 테스트 90% 이상 통과
- [ ] API 응답 시간 < 200ms

### 최종 성공 지표
- [ ] 4개 마이크로서비스 독립 실행
- [ ] Kubernetes 클러스터 배포 성공
- [ ] 서비스 간 통신 정상 작동
- [ ] 기본 CRUD 기능 완성
- [ ] 세션 기반 인증 구현
- [ ] 파일 업로드/다운로드 기능
- [ ] 실시간 통계 대시보드
- [ ] 부하 테스트 통과 (동시 사용자 100명)

## 참고사항

- 로컬 개발 및 테스트 환경에서만 실행
- 실제 배포는 하지 않음
- 졸업 작품 데모를 위한 구현
- 모든 서비스는 Ruby on Rails 8로 통일
- 세션 기반 인증 (JWT 사용하지 않음)