# TaskMate

마이크로서비스 아키텍처 기반 할일 관리 플랫폼

## 프로젝트 소개

TaskMate는 Ruby on Rails 8을 기반으로 구축된 마이크로서비스 아키텍처(MSA) 할일 관리 애플리케이션입니다. 
4개의 독립적인 서비스로 구성되어 있으며, Kubernetes 환경에서 운영됩니다.

## 마이크로서비스 구성

- **User Service** (포트 3000): 사용자 인증 및 세션 관리
- **Task Service** (포트 3001): 할일 CRUD 및 상태 관리
- **Analytics Service** (포트 3002): 통계 및 대시보드
- **File Service** (포트 3003): 파일 첨부 관리

## 기술 스택

- **Backend**: Ruby on Rails 8
- **Database**: PostgreSQL
- **Cache**: Redis
- **Container**: Docker
- **Orchestration**: Kubernetes (minikube)
- **Frontend**: Rails Views + Tailwind CSS + Turbo/Stimulus

## 프로젝트 구조

```
taskmate/
├── services/
│   ├── user-service/
│   ├── task-service/
│   ├── analytics-service/
│   └── file-service/
├── k8s/
│   ├── deployments/
│   ├── services/
│   └── ingress/
├── docker/
└── docs/
```

## 개발 환경 설정

### 필수 요구사항

- Ruby 3.4.3
- Rails 8
- PostgreSQL
- Redis
- Docker
- minikube

### 설치 방법

```bash
# Ruby 설치 (rbenv 사용)
rbenv install 3.4.3
rbenv local 3.4.3

# 의존성 설치
bundle install

# 데이터베이스 설정
rails db:create
rails db:migrate

# 개발 서버 실행
bin/dev
```

## 문서

자세한 내용은 [PROJECT_PLAN.md](PROJECT_PLAN.md)를 참고하세요.

## 라이센스

MIT License
