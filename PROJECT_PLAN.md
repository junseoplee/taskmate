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

### ✅ Phase 1 완료: Docker 인프라 구성 (2024-01-15)
- ✅ Ruby 3.4.3 및 Rails 8 프로젝트 초기화 완료
- ✅ PostgreSQL, Tailwind CSS 설정 완료
- ✅ 프로젝트 문서화 (README, PROJECT_PLAN, CLAUDE.md) 완료
- ✅ GitHub 저장소 설정 및 이니셜 커밋 완료
- ✅ Docker 환경 구성 완료
  - ✅ 루트 레벨 `docker-compose.yml` 생성
  - ✅ PostgreSQL 서비스 설정 (포트 5432, 멀티 DB 지원)
  - ✅ Redis 서비스 설정 (포트 6379)
  - ✅ 각 마이크로서비스용 컨테이너 정의
  - ✅ 멀티 데이터베이스 생성 스크립트 작성
  - ✅ 개발용 `Dockerfile.rails` 생성
  - ✅ Docker 네트워크 설정 (서비스 간 통신)
- ✅ 프로젝트 디렉토리 구조 생성
  - ✅ `services/` 디렉토리 (user-service, task-service, analytics-service, file-service)
  - ✅ `k8s/` 디렉토리 (deployments, services, ingress, configmaps)
  - ✅ `docker/` 디렉토리 (development, production)
  - ✅ `docs/` 디렉토리 (api, architecture, deployment)
- ✅ 개발 환경 스크립트 작성
  - ✅ `scripts/setup.sh` - 초기 환경 설정
  - ✅ `scripts/dev.sh` - 개발 서버 실행
  - ✅ `scripts/test.sh` - 테스트 실행
  - ✅ `scripts/build.sh` - Docker 이미지 빌드
  - ✅ `scripts/create-multiple-postgresql-databases.sh` - 멀티 DB 구성
- ✅ 상세 문서화 완료
  - ✅ `docs/TDD_GUIDE.md` - RSpec 기반 테스트 전략 및 가이드라인
  - ✅ `docs/PHASE2_EXECUTION_PLAN.md` - 상세 구현 체크리스트
  - ✅ `docs/API_SPECIFICATION.md` - OpenAPI 3.0 명세서
  - ✅ `docs/SETUP.md` - 개발 환경 설정 가이드

**검증 완료**:
- ✅ PostgreSQL 4개 DB 생성: user_service_db, task_service_db, analytics_service_db, file_service_db
- ✅ Redis 정상 실행 (포트 6379)
- ✅ Docker 컨테이너 헬스체크 통과
- ✅ 개발 스크립트 동작 확인

### ⏳ Phase 2: 핵심 서비스 개발 (User + Task) - 준비 완료
**예상 소요시간**: 8-10일  
**우선순위**: HIGH  
**의존성**: Phase 1 완료 ✅  
**준비 상태**: 문서화 완료, 실행 계획 수립

TDD 기반 마이크로서비스 개발로 세션 기반 인증 시스템과 태스크 관리 기능을 구현합니다.

**준비 완료 사항**:
- ✅ TDD 가이드라인 수립 (`docs/TDD_GUIDE.md`)
- ✅ 상세 실행 계획 작성 (`docs/PHASE2_EXECUTION_PLAN.md`)
- ✅ API 명세서 작성 (`docs/API_SPECIFICATION.md`)
- ✅ 테스트 전략 및 환경 설정 완료

**Phase 2 성공 기준**:
- 테스트 커버리지 80% 이상
- API 응답 시간 200ms 미만
- 서비스 간 통신 정상 동작
- 회원가입/로그인/태스크 CRUD 기능 완성

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
**예상 소요시간**: 6-8일  
**우선순위**: MEDIUM  
**의존성**: Phase 2 완료

이벤트 기반 통신을 통한 통계 분석 서비스와 파일 관리 서비스 구현

**주요 태스크:**
- [ ] **Analytics Service 구현** (3-4일)
  - [ ] Rails API 프로젝트 생성 (포트 3002)
  - [ ] Event 모델 및 통계 집계 로직 설계
  - [ ] 이벤트 수신 시스템 (비동기 처리)
  - [ ] 대시보드 API (완료율, 우선순위별 분포)
  - [ ] Redis 기반 실시간 통계 캐싱
  - [ ] 통계 배치 작업 스케줄링

- [ ] **File Service 구현** (3-4일)
  - [ ] Rails API 프로젝트 생성 (포트 3003)
  - [ ] Active Storage 설정 및 파일 업로드/다운로드 API
  - [ ] 파일 메타데이터 관리 (크기, 타입, 체크섬)
  - [ ] 태스크별 첨부파일 연결 시스템
  - [ ] 파일 보안 및 접근 권한 관리
  - [ ] 자동 파일 정리 배치 작업

- [ ] **서비스 간 통신 강화**
  - [ ] 이벤트 기반 통신 구현 (Task → Analytics)
  - [ ] Circuit Breaker 패턴 적용
  - [ ] 서비스 디스커버리 기초 구현
  - [ ] 통합 테스트 및 E2E 테스트

**성공 기준**:
- 실시간 대시보드 데이터 업데이트
- 파일 업로드/다운로드 안정성
- 이벤트 처리 지연시간 < 1초

### Phase 4: Frontend UI/UX 개발
**예상 소요시간**: 5-7일  
**우선순위**: HIGH  
**의존성**: Phase 2-3 완료

사용자 친화적인 웹 인터페이스 구현으로 마이크로서비스 기능을 통합

**주요 태스크:**
- [ ] **기본 UI 프레임워크** (1-2일)
  - [ ] Tailwind CSS 기반 디자인 시스템 구축
  - [ ] 반응형 레이아웃 및 네비게이션 구현
  - [ ] 컴포넌트 라이브러리 설계
  - [ ] 다크/라이트 모드 지원

- [ ] **인증 및 사용자 관리 UI** (1-2일)
  - [ ] 로그인/회원가입 페이지 (폼 유효성 검증)
  - [ ] 사용자 프로필 관리 페이지
  - [ ] 세션 관리 및 자동 로그아웃 처리
  - [ ] 에러 처리 및 사용자 피드백

- [ ] **태스크 관리 인터페이스** (2-3일)
  - [ ] 태스크 목록 (필터링, 정렬, 페이징)
  - [ ] 태스크 생성/수정 모달
  - [ ] 드래그 앤 드롭 상태 변경
  - [ ] 태스크 상세 보기 및 첨부파일 관리

- [ ] **대시보드 및 통계** (1-2일)
  - [ ] Chart.js 기반 통계 차트 구현
  - [ ] 실시간 데이터 업데이트 (Turbo Streams)
  - [ ] 완료율, 우선순위별 분포 시각화
  - [ ] 개인 생산성 지표 표시

**기술 스택**:
- Rails Views (ERB) + Turbo + Stimulus
- Tailwind CSS + HeadlessUI
- Chart.js for 데이터 시각화
- 파일 업로드: Dropzone.js

**성공 기준**:
- 모바일 친화적 반응형 디자인
- 직관적인 사용자 경험
- 페이지 로딩 시간 < 2초

### Phase 5: Kubernetes 배포 및 운영
**예상 소요시간**: 4-6일  
**우선순위**: MEDIUM  
**의존성**: Phase 4 완료

프로덕션 레벨 컨테이너 오케스트레이션 및 배포 자동화 구현

**주요 태스크:**
- [ ] **Docker 컨테이너화** (1-2일)
  - [ ] 각 서비스별 멀티스테이지 Dockerfile 최적화
  - [ ] Docker Compose 프로덕션 설정
  - [ ] 이미지 크기 최적화 (Alpine Linux 기반)
  - [ ] 보안 스캐닝 및 취약점 점검

- [ ] **Kubernetes 클러스터 구성** (2-3일)
  - [ ] minikube 로컬 클러스터 설정
  - [ ] Namespace 및 리소스 할당 정책
  - [ ] Deployment, Service, ConfigMap 매니페스트
  - [ ] PersistentVolume (PostgreSQL, Redis 데이터)
  - [ ] HorizontalPodAutoscaler 설정

- [ ] **네트워킹 및 보안** (1-2일)
  - [ ] NGINX Ingress Controller 설정
  - [ ] TLS/SSL 인증서 관리
  - [ ] 서비스 간 네트워크 정책
  - [ ] Secret 관리 (DB 패스워드, API 키)

**성공 기준**:
- 4개 마이크로서비스 독립 배포
- 자동 스케일링 동작
- 무중단 롤링 업데이트

### Phase 6: 모니터링 및 관찰성 구현
**예상 소요시간**: 3-5일  
**우선순위**: HIGH  
**의존성**: Phase 5 완료

프로덕션 환경의 시스템 안정성과 성능 모니터링을 위한 관찰성 스택 구축

**주요 태스크:**
- [ ] **메트릭 수집 및 모니터링** (1-2일)
  - [ ] Prometheus + Grafana 스택 구축
  - [ ] 애플리케이션 메트릭 수집 (응답시간, 에러율, 처리량)
  - [ ] 인프라 메트릭 모니터링 (CPU, 메모리, 네트워크)
  - [ ] 사용자 정의 대시보드 구성

- [ ] **로깅 및 추적** (1-2일)
  - [ ] ELK Stack (Elasticsearch, Logstash, Kibana) 구성
  - [ ] 구조화된 로깅 및 Correlation ID 추적
  - [ ] 로그 집계 및 검색 최적화
  - [ ] 에러 로그 알림 시스템

- [ ] **헬스체크 및 알림** (1일)
  - [ ] 서비스별 Health Check 엔드포인트 강화
  - [ ] Kubernetes Liveness/Readiness Probe 설정
  - [ ] Slack/Email 알림 시스템 구축
  - [ ] SLA 기반 알림 임계값 설정

**성공 기준**:
- 평균 장애 감지 시간 < 30초
- 99.9% 가용성 달성
- 포괄적인 성능 가시성 확보

### Phase 7: 종합 테스트 및 성능 최적화
**예상 소요시간**: 4-6일  
**우선순위**: HIGH  
**의존성**: Phase 6 완료

시스템 전체의 품질 보증과 성능 최적화를 통한 프로덕션 준비

**주요 태스크:**
- [ ] **테스트 자동화 강화** (2-3일)
  - [ ] E2E 테스트 시나리오 완성 (Cypress/Playwright)
  - [ ] API 계약 테스트 (Pact/Schema validation)
  - [ ] 카오스 엔지니어링 기초 (서비스 장애 시뮬레이션)
  - [ ] CI/CD 파이프라인 테스트 자동화

- [ ] **성능 테스트 및 최적화** (1-2일)
  - [ ] 부하 테스트 (Apache JMeter/k6)
  - [ ] 동시 사용자 100명 처리 능력 검증
  - [ ] 데이터베이스 쿼리 최적화
  - [ ] 캐싱 전략 개선 (Redis 활용)

- [ ] **보안 강화** (1일)
  - [ ] 보안 취약점 스캔 (OWASP ZAP)
  - [ ] 인증/인가 로직 보안 검토
  - [ ] 민감 정보 보호 점검
  - [ ] Rate Limiting 구현

**성능 목표**:
- 동시 사용자 100명 지원
- API 응답 시간 < 200ms (95th percentile)
- 시스템 가용성 99.9%

### Phase 8: 문서화 및 프로젝트 완성
**예상 소요시간**: 3-4일  
**우선순위**: HIGH  
**의존성**: Phase 7 완료

프로젝트 완성도를 높이고 지식 전수를 위한 포괄적 문서화 및 시연 준비

**주요 태스크:**
- [ ] **기술 문서화** (1-2일)
  - [ ] API 문서 자동 생성 (Swagger/OpenAPI)
  - [ ] 아키텍처 다이어그램 및 시스템 설계 문서
  - [ ] 운영 가이드 (배포, 모니터링, 트러블슈팅)
  - [ ] 개발자 온보딩 가이드

- [ ] **사용자 문서화** (1일)
  - [ ] 사용자 매뉴얼 및 튜토리얼 작성
  - [ ] 기능별 가이드 및 FAQ
  - [ ] 스크린샷 및 동영상 가이드
  - [ ] 접근성 가이드

- [ ] **프로젝트 정리** (1일)
  - [ ] 코드 리팩토링 및 주석 정리
  - [ ] 불필요한 파일 및 의존성 정리
  - [ ] Git 히스토리 정리 및 태그 생성
  - [ ] README.md 최종 업데이트

- [ ] **시연 준비** (0.5일)
  - [ ] 데모 시나리오 및 테스트 데이터 준비
  - [ ] 프레젠테이션 자료 작성
  - [ ] 핵심 기능 시연 스크립트
  - [ ] Q&A 대비 자료 준비

**최종 산출물**:
- 완전히 동작하는 마이크로서비스 시스템
- 포괄적인 기술 문서
- 사용자 친화적 웹 인터페이스
- 프로덕션 레벨 운영 환경

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

### 📅 전체 개발 일정 (총 35-50일)

**Phase 1**: ✅ 완료 (Docker 인프라)  
**Phase 2**: 8-10일 (핵심 서비스)  
**Phase 3**: 6-8일 (확장 서비스)  
**Phase 4**: 5-7일 (Frontend)  
**Phase 5**: 4-6일 (Kubernetes)  
**Phase 6**: 3-5일 (모니터링)  
**Phase 7**: 4-6일 (테스트/최적화)  
**Phase 8**: 3-4일 (문서화)  

### 🚀 Week 1-2: 핵심 마이크로서비스 구현
1. **✅ Phase 1 완료**: Docker 환경 및 문서화 
2. **⏳ Phase 2 시작**: User Service + Task Service TDD 구현
   - User Service 구현 (4-5일)
   - Task Service 구현 (3-4일)
   - 서비스 간 통신 및 통합 테스트 (1일)

### 🏗️ Week 3-4: 확장 서비스 및 UI
3. **Phase 3**: Analytics + File Service 구현 (6-8일)
4. **Phase 4**: Frontend UI/UX 개발 (5-7일)

### 📈 Week 5-7: 운영 환경 구축
5. **Phase 5**: Kubernetes 배포 환경 (4-6일)
6. **Phase 6**: 모니터링 및 관찰성 (3-5일)
7. **Phase 7**: 성능 테스트 및 최적화 (4-6일)

### 🎯 Week 8: 프로젝트 완성
8. **Phase 8**: 문서화 및 시연 준비 (3-4일)

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

### ✅ Phase 1 완료 기준 (달성 완료)
- ✅ `docker-compose up`으로 모든 서비스 실행 가능
- ✅ 개발 스크립트 (`scripts/dev.sh`) 동작 확인
- ✅ PostgreSQL, Redis 연결 확인
- ✅ 상세 문서화 및 실행 계획 수립

### 🎯 Phase 2 완료 기준 (진행 예정)
- [ ] 회원가입/로그인 API 정상 동작
- [ ] 태스크 CRUD API 정상 동작
- [ ] 서비스 간 인증 검증 정상 동작
- [ ] 통합 테스트 90% 이상 통과
- [ ] API 응답 시간 < 200ms
- [ ] 테스트 커버리지 80% 이상

### 🏆 최종 성공 지표
- [ ] **기능 완성도**
  - 4개 마이크로서비스 독립 실행
  - 기본 CRUD 기능 완성
  - 세션 기반 인증 구현
  - 파일 업로드/다운로드 기능
  - 실시간 통계 대시보드

- [ ] **기술적 성취**
  - Kubernetes 클러스터 배포 성공
  - 서비스 간 통신 정상 작동
  - TDD 기반 개발 완료
  - CI/CD 파이프라인 구축

- [ ] **성능 및 안정성**
  - 부하 테스트 통과 (동시 사용자 100명)
  - 시스템 가용성 99.9%
  - API 응답 시간 < 200ms (95th percentile)
  - 테스트 커버리지 80% 이상

- [ ] **운영 준비도**
  - 모니터링 대시보드 구축
  - 자동 스케일링 동작
  - 포괄적인 문서화 완성
  - 시연 및 발표 준비 완료

## 참고사항

- 로컬 개발 및 테스트 환경에서만 실행
- 실제 배포는 하지 않음
- 졸업 작품 데모를 위한 구현
- 모든 서비스는 Ruby on Rails 8로 통일
- 세션 기반 인증 (JWT 사용하지 않음)