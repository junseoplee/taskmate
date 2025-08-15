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

### 1. User Service (포트 3000)
- 사용자 인증/인가
- 세션 관리
- 프로필 관리
- 다른 서비스의 인증 검증 API 제공

### 2. Task Service (포트 3001)
- 할일 CRUD
- 상태 관리 (진행중/완료/보류)
- 우선순위 및 마감일 관리

### 3. Analytics Service (포트 3002)
- 통계 데이터 집계
- 완료율/진행률 계산
- 대시보드 데이터 제공

### 4. File Service (포트 3003)
- 파일 업로드/다운로드
- 파일 메타데이터 관리
- 태스크별 첨부파일 관리

## 개발 페이즈

### Phase 1: 프로젝트 초기 설정
**태스크:**
- [x] Ruby 3.4.3 및 Rails 8 설치
- [x] 프로젝트 기본 구조 생성
- [x] Git 저장소 초기화
- [ ] Docker 환경 구성
- [ ] 개발 환경 설정 문서화

### Phase 2: 핵심 서비스 개발 (User + Task)
**태스크:**
- [ ] User Service 구현
  - [ ] Rails 프로젝트 생성
  - [ ] 사용자 모델 및 마이그레이션
  - [ ] 인증 컨트롤러 구현
  - [ ] 세션 관리 시스템
  - [ ] 인증 검증 API 엔드포인트
- [ ] Task Service 구현
  - [ ] Rails 프로젝트 생성
  - [ ] 태스크 모델 및 마이그레이션
  - [ ] CRUD API 구현
  - [ ] User Service 연동
- [ ] 서비스 간 통신 구현
- [ ] 통합 테스트

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

## 개발 우선순위

1. **필수 기능** (Phase 1-3)
   - 기본 CRUD
   - 사용자 인증
   - 세션 관리

2. **핵심 기능** (Phase 4-5)
   - 파일 첨부
   - 통계/대시보드
   - UI/UX

3. **고급 기능** (Phase 6-8)
   - 모니터링
   - 자동 스케일링
   - 성능 최적화

## 성공 지표

- [ ] 4개 마이크로서비스 독립 실행
- [ ] Kubernetes 클러스터 배포 성공
- [ ] 서비스 간 통신 정상 작동
- [ ] 기본 CRUD 기능 완성
- [ ] 세션 기반 인증 구현
- [ ] 파일 업로드/다운로드 기능
- [ ] 실시간 통계 대시보드
- [ ] 부하 테스트 통과

## 참고사항

- 로컬 개발 및 테스트 환경에서만 실행
- 실제 배포는 하지 않음
- 졸업 작품 데모를 위한 구현
- 모든 서비스는 Ruby on Rails 8로 통일
- 세션 기반 인증 (JWT 사용하지 않음)