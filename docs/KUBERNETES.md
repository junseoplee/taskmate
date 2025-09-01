# TaskMate Kubernetes 배포 가이드

## 개요

TaskMate는 Ruby on Rails 8 기반의 마이크로서비스 애플리케이션으로, Kubernetes 환경에서 5개의 독립적인 서비스로 구성됩니다. 본 문서는 Docker Compose에서 Kubernetes로 마이그레이션된 시스템의 아키텍처와 운영 방법을 설명합니다.

## 🏗️ 시스템 아키텍처

### 서비스 구조

```
┌─────────────────────────────────────────────────────────────┐
│                    NGINX Ingress Controller                 │
│                      (Port: 80)                            │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│              Frontend Service (Port: 3100)                 │
│          Web UI + API Gateway 역할                         │
│     - Rails Views (Tailwind CSS)                          │
│     - Session Management                                   │
│     - Backend Service Integration                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────────────────────┐
        │             │                             │
        ▼             ▼                             ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│User Service │ │Task Service │ │Analytics    │ │File Service │
│(Port: 3000) │ │(Port: 3001) │ │Service      │ │(Port: 3003) │
│             │ │             │ │(Port: 3002) │ │             │
│- 인증 관리   │ │- 태스크 CRUD│ │- 통계 분석   │ │- 파일 업로드 │
│- 세션 관리   │ │- 태스크 상태 │ │- 대시보드    │ │- 첨부파일    │
│- 사용자 API │ │- 프로젝트    │ │- 리포팅     │ │- 카테고리    │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
        │             │                             │
        └─────────────┼─────────────────────────────┘
                      ▼
        ┌─────────────────────────────────────┐
        │         PostgreSQL                  │
        │    (Multi-Database Architecture)    │
        │                                     │
        │ ├── user_service_db                 │
        │ ├── task_service_db                 │
        │ ├── analytics_service_db            │
        │ └── file_service_db                 │
        └─────────────────────────────────────┘
                      │
                      ▼
        ┌─────────────────────────────────────┐
        │             Redis                   │
        │      (Session Store & Cache)        │
        └─────────────────────────────────────┘
```

### 통신 패턴

1. **프론트엔드 → 백엔드**: HTTP 기반 Service Client 패턴
2. **서비스 간 통신**: REST API (HTTParty 라이브러리 사용)
3. **세션 관리**: Redis 기반 세션 스토어
4. **데이터베이스**: PostgreSQL 멀티 데이터베이스 구조

## 📦 Kubernetes 리소스 구조

### 네임스페이스 및 설정

```
k8s/
├── namespace.yaml              # 네임스페이스, ConfigMap, Secrets
├── infrastructure/
│   ├── postgres.yaml          # PostgreSQL 배포
│   └── redis.yaml             # Redis 배포
├── services/
│   ├── user-service.yaml      # User Service 배포
│   ├── task-service.yaml      # Task Service 배포
│   ├── analytics-service.yaml # Analytics Service 배포
│   ├── file-service.yaml      # File Service 배포
│   └── frontend-service.yaml  # Frontend Service 배포
└── networking/
    └── ingress.yaml           # NGINX Ingress 설정
```

### 핵심 구성 요소

#### 1. ConfigMap (환경 변수)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: taskmate-config
  namespace: taskmate
data:
  POSTGRES_HOST: "postgres"
  POSTGRES_PORT: "5432"
  POSTGRES_USER: "taskmate"
  REDIS_URL: "redis://redis:6379"
  USER_SERVICE_URL: "http://user-service:3000"
  TASK_SERVICE_URL: "http://task-service:3001"
  ANALYTICS_SERVICE_URL: "http://analytics-service:3002"
  FILE_SERVICE_URL: "http://file-service:3003"
```

#### 2. Secrets (민감한 정보)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: taskmate-secrets
  namespace: taskmate
stringData:
  DATABASE_PASSWORD: "password"
  RAILS_MASTER_KEY: "dummy_master_key_for_development_only"
```

#### 3. 서비스 배포 예시 (User Service)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: taskmate
spec:
  replicas: 1
  selector:
    matchLabels:
      app: user-service
  template:
    spec:
      initContainers:
      - name: db-migrate
        image: taskmate/user-service:latest
        imagePullPolicy: Never
        command: ["./bin/rails", "db:migrate"]
        env:
        - name: RAILS_ENV
          value: "development"
        envFrom:
        - configMapRef:
            name: taskmate-config
        - secretRef:
            name: taskmate-secrets
      containers:
      - name: user-service
        image: taskmate/user-service:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
        env:
        - name: RAILS_ENV
          value: "development"
        - name: RAILS_MASTER_KEY_DUMMY
          value: "1"
        envFrom:
        - configMapRef:
            name: taskmate-config
        - secretRef:
            name: taskmate-secrets
```

## 🚀 설치 및 실행 가이드

### 1. 사전 요구사항

- Docker Desktop 설치 및 실행
- Minikube 설치 및 실행
- kubectl 설치
- NGINX Ingress Controller 설치

```bash
# Minikube 시작
minikube start

# NGINX Ingress 활성화
minikube addons enable ingress

# Ingress Controller 상태 확인
kubectl get pods -n ingress-nginx
```

### 2. Docker 이미지 빌드

각 서비스별로 Docker 이미지를 빌드합니다:

```bash
# 프로젝트 루트 디렉토리에서
cd /Users/junseop/Documents/work/taskmate

# User Service 이미지 빌드
docker build -f services/user-service/Dockerfile.dev -t taskmate/user-service:latest services/user-service

# Task Service 이미지 빌드
docker build -f services/task-service/Dockerfile.dev -t taskmate/task-service:latest services/task-service

# Analytics Service 이미지 빌드
docker build -f services/analytics-service/Dockerfile.dev -t taskmate/analytics-service:latest services/analytics-service

# File Service 이미지 빌드
docker build -f services/file-service/Dockerfile.dev -t taskmate/file-service:latest services/file-service

# Frontend Service 이미지 빌드
docker build -f services/frontend-service/Dockerfile.dev -t taskmate/frontend-service:latest services/frontend-service
```

### 3. Kubernetes 배포

#### 단계별 배포 순서

```bash
# 1. 네임스페이스 및 기본 설정 배포
kubectl apply -f k8s/namespace.yaml

# 2. 인프라 서비스 배포 (PostgreSQL, Redis)
kubectl apply -f k8s/infrastructure/

# 3. 인프라 서비스 준비 대기 (약 30-60초)
kubectl wait --for=condition=ready pod -l app=postgres -n taskmate --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n taskmate --timeout=300s

# 4. 백엔드 서비스 배포
kubectl apply -f k8s/services/user-service.yaml
kubectl apply -f k8s/services/task-service.yaml
kubectl apply -f k8s/services/analytics-service.yaml
kubectl apply -f k8s/services/file-service.yaml

# 5. 백엔드 서비스 준비 대기 (약 60-120초)
kubectl wait --for=condition=ready pod -l app=user-service -n taskmate --timeout=300s
kubectl wait --for=condition=ready pod -l app=task-service -n taskmate --timeout=300s
kubectl wait --for=condition=ready pod -l app=analytics-service -n taskmate --timeout=300s
kubectl wait --for=condition=ready pod -l app=file-service -n taskmate --timeout=300s

# 6. 프론트엔드 서비스 배포
kubectl apply -f k8s/services/frontend-service.yaml

# 7. 프론트엔드 서비스 준비 대기
kubectl wait --for=condition=ready pod -l app=frontend-service -n taskmate --timeout=300s

# 8. Ingress 배포
kubectl apply -f k8s/networking/ingress.yaml
```

### 4. 배포 상태 확인

```bash
# 모든 Pod 상태 확인
kubectl get pods -n taskmate

# 서비스 상태 확인
kubectl get services -n taskmate

# Ingress 상태 확인
kubectl get ingress -n taskmate

# 전체 리소스 확인
kubectl get all -n taskmate
```

정상 배포 시 다음과 같은 상태를 확인할 수 있습니다:

```
NAME                                   READY   STATUS    RESTARTS   AGE
pod/analytics-service-xxx              1/1     Running   0          5m
pod/file-service-xxx                   1/1     Running   0          5m
pod/frontend-service-xxx               1/1     Running   0          3m
pod/postgres-xxx                       1/1     Running   0          10m
pod/redis-xxx                          1/1     Running   0          10m
pod/task-service-xxx                   1/1     Running   0          5m
pod/user-service-xxx                   1/1     Running   0          5m
```

### 5. 애플리케이션 접속

#### 포트 포워딩을 통한 접속

```bash
# Frontend Service 포트 포워딩 (권장)
kubectl port-forward service/frontend-service 3100:3100 -n taskmate

# 브라우저에서 접속
open http://localhost:3100
```

#### Ingress를 통한 접속

```bash
# Minikube IP 확인
minikube ip

# /etc/hosts 파일에 추가
echo "$(minikube ip) taskmate.local" | sudo tee -a /etc/hosts

# 브라우저에서 접속
open http://taskmate.local
```

## 🔧 운영 및 관리

### 로그 확인

```bash
# 특정 서비스 로그 확인
kubectl logs -l app=user-service -n taskmate -f

# 전체 서비스 로그 확인
kubectl logs -l tier=backend -n taskmate -f

# 특정 Pod 로그 확인
kubectl logs <pod-name> -n taskmate -f
```

### 스케일링

```bash
# 서비스 스케일 업
kubectl scale deployment user-service --replicas=3 -n taskmate

# 현재 레플리카 상태 확인
kubectl get deployments -n taskmate
```

### 데이터베이스 관리

```bash
# PostgreSQL Pod에 접속
kubectl exec -it deployment/postgres -n taskmate -- psql -U taskmate -d postgres

# 데이터베이스 목록 확인
\l

# 특정 데이터베이스 접속
\c user_service_db

# 테이블 확인
\dt
```

### 서비스 업데이트

```bash
# 새로운 이미지 빌드 후
docker build -f services/user-service/Dockerfile.dev -t taskmate/user-service:latest services/user-service

# 배포 재시작
kubectl rollout restart deployment/user-service -n taskmate

# 롤아웃 상태 확인
kubectl rollout status deployment/user-service -n taskmate
```

## 🐛 트러블슈팅

### 일반적인 문제 해결

#### 1. ImagePullBackOff 오류
```bash
# 로컬 이미지 확인
docker images | grep taskmate

# Pod 상태 상세 확인
kubectl describe pod <pod-name> -n taskmate
```

**해결방법**: 모든 배포에서 `imagePullPolicy: Never` 설정 확인

#### 2. CrashLoopBackOff 오류
```bash
# Pod 로그 확인
kubectl logs <pod-name> -n taskmate

# 이전 컨테이너 로그 확인
kubectl logs <pod-name> -n taskmate --previous
```

**일반적인 원인**:
- 데이터베이스 연결 실패
- 환경 변수 누락
- 마이그레이션 오류

#### 3. 서비스 간 통신 오류
```bash
# 서비스 DNS 확인
kubectl exec -it <pod-name> -n taskmate -- nslookup user-service

# 포트 연결 테스트
kubectl exec -it <pod-name> -n taskmate -- curl http://user-service:3000/up
```

#### 4. 데이터베이스 연결 문제
```bash
# PostgreSQL 상태 확인
kubectl exec -it deployment/postgres -n taskmate -- pg_isready

# 데이터베이스 연결 테스트
kubectl exec -it deployment/postgres -n taskmate -- psql -U taskmate -l
```

### 성능 모니터링

```bash
# 리소스 사용량 확인
kubectl top nodes
kubectl top pods -n taskmate

# 서비스 응답 시간 테스트
kubectl run test-pod --image=curlimages/curl -it --rm -n taskmate -- sh
# Pod 내에서: curl -w "@curl-format.txt" http://user-service:3000/api/v1/auth/verify
```

## 🔄 CI/CD 통합 (향후 계획)

### GitHub Actions 워크플로우 예시

```yaml
name: Deploy to Kubernetes
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Build Images
      run: |
        docker build -f services/user-service/Dockerfile.dev -t taskmate/user-service:${{ github.sha }} services/user-service
        # ... 다른 서비스들
    
    - name: Deploy to Kubernetes
      run: |
        kubectl set image deployment/user-service user-service=taskmate/user-service:${{ github.sha }} -n taskmate
        kubectl rollout status deployment/user-service -n taskmate
```

## 📊 모니터링 및 로깅 (향후 계획)

### Prometheus + Grafana 통합
- 서비스 메트릭 수집
- 대시보드 구성
- 알림 설정

### ELK Stack 통합
- 중앙화된 로그 관리
- 로그 분석 및 검색
- 실시간 모니터링

## 🛡️ 보안 고려사항

### 현재 구현
- Kubernetes Secrets를 통한 민감 정보 관리
- 네임스페이스 기반 격리
- 서비스 간 내부 통신

### 향후 개선 계획
- RBAC (Role-Based Access Control) 구현
- Network Policies 적용
- Pod Security Standards 적용
- TLS/SSL 인증서 적용

## 🔄 Docker Compose에서 Kubernetes 마이그레이션 경험

### 마이그레이션 배경 및 목표

**기존 환경 (Docker Compose)**:
- 단일 호스트 배포로 확장성 제한
- 수동 서비스 관리 및 모니터링
- 로드밸런싱 및 고가용성 부족
- 개발/프로덕션 환경 차이

**Kubernetes 마이그레이션 목표**:
- 확장 가능한 마이크로서비스 아키텍처
- 자동화된 배포 및 관리
- 고가용성 및 장애 복구
- 표준화된 개발/운영 환경

### 🏗️ 아키텍처 설계 결정사항

#### 1. 네임스페이스 전략
**선택**: 단일 `taskmate` 네임스페이스
**이유**:
- 개발 환경의 단순성
- 서비스 간 통신의 편의성
- 리소스 관리의 일관성
- 향후 환경별(dev/staging/prod) 분리 가능

#### 2. 서비스 메시 vs 직접 통신
**선택**: 직접 서비스 통신 (Service Client 패턴)
**이유**:
- 마이크로서비스 수가 적음 (5개)
- 복잡성 대비 이점이 적음
- 기존 HTTParty 코드 재사용
- 디버깅 및 모니터링 용이성

#### 3. 데이터베이스 아키텍처
**선택**: 단일 PostgreSQL 인스턴스 + 멀티 데이터베이스
**이유**:
- 개발 환경의 복잡성 최소화
- 백업 및 복원의 일관성
- 트랜잭션 무결성 보장
- 향후 데이터베이스 분리 가능

```yaml
# 선택한 구조
PostgreSQL (단일 Pod)
├── user_service_db
├── task_service_db  
├── analytics_service_db
└── file_service_db

# 대안 (복잡성 때문에 배제)
- PostgreSQL Operator 사용
- 서비스별 독립 PostgreSQL 인스턴스
- 외부 관리형 데이터베이스 서비스
```

#### 4. 이미지 관리 전략
**선택**: 로컬 이미지 + `imagePullPolicy: Never`
**이유**:
- 개발 환경의 빠른 이터레이션
- 네트워크 의존성 제거
- 이미지 레지스트리 설정 복잡성 회피
- Minikube 환경의 특성 활용

### 🚧 마이그레이션 과정에서 해결한 주요 이슈

#### 1. ImagePullBackOff 문제
**문제**: Kubernetes가 Docker Hub에서 이미지를 다운로드하려고 시도
**원인**: 기본 `imagePullPolicy`가 로컬 이미지를 무시
**해결방법**:
```yaml
containers:
- name: service-name
  image: taskmate/service-name:latest
  imagePullPolicy: Never  # 로컬 이미지만 사용
```

#### 2. Rails 환경 변수 문제
**문제**: `SECRET_KEY_BASE` 길이 오류 및 환경 변수 충돌
**원인**: Rails 8의 새로운 보안 정책
**해결방법**:
```yaml
env:
- name: RAILS_MASTER_KEY_DUMMY
  value: "1"  # 개발 환경용 더미 키 활성화
```

#### 3. 동시 마이그레이션 오류
**문제**: 여러 Pod이 동시에 DB 마이그레이션 실행
**원인**: 스케일 아웃된 Pod들이 동시 실행
**해결방법**:
```bash
# 배포 후 스케일을 1로 제한
kubectl scale deployment --replicas=1 -n taskmate --all
```

#### 4. InitContainer 활용
**문제**: 서비스 시작 전 DB 마이그레이션 필요
**해결방법**:
```yaml
initContainers:
- name: db-migrate
  image: taskmate/user-service:latest
  command: ["./bin/rails", "db:migrate"]
  # 메인 컨테이너 시작 전에 마이그레이션 실행
```

### 🎯 성능 및 안정성 최적화

#### 1. 리소스 관리
**현재 설정**: 개발 환경 기본값 사용
**향후 계획**:
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi" 
    cpu: "500m"
```

#### 2. Health Check 전략
**구현**: Rails의 `/up` 엔드포인트 활용
```yaml
livenessProbe:
  httpGet:
    path: /up
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /up
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
```

#### 3. 배포 순서 최적화
**중요**: 의존성 기반 단계적 배포
```bash
1. 인프라 (PostgreSQL, Redis)
2. 백엔드 서비스 (병렬 배포)
3. 프론트엔드 서비스
4. 네트워킹 (Ingress)
```

### 🔍 모니터링 및 디버깅 전략

#### 1. 로그 중앙화
**현재**: `kubectl logs` 사용
**향후**: ELK Stack 또는 Loki 도입 예정

#### 2. 메트릭 수집
**현재**: 기본 Kubernetes 메트릭
**계획**: Prometheus + Grafana 통합

#### 3. 분산 추적
**향후**: Jaeger 또는 Zipkin 도입 검토

### 📊 성능 비교: Docker Compose vs Kubernetes

| 항목 | Docker Compose | Kubernetes | 개선사항 |
|------|----------------|------------|-----------|
| 시작 시간 | ~30초 | ~2분 | 초기 설정 시간 증가하지만 안정성 향상 |
| 리소스 사용량 | 낮음 | 중간 | Control Plane 오버헤드 있지만 효율적 스케줄링 |
| 가용성 | 단일 장애점 | 자동 복구 | Pod 재시작, 로드밸런싱으로 향상 |
| 스케일링 | 수동 | 자동/수동 | HPA, VPA로 자동 확장 가능 |
| 배포 | 수동 | 선언적 | GitOps 워크플로우 적용 가능 |

### 🚀 실제 배포 경험 및 교훈

#### 성공 요인
1. **점진적 마이그레이션**: Docker Compose 환경을 유지하며 병렬 개발
2. **단계적 접근**: 인프라 → 백엔드 → 프론트엔드 순서로 검증
3. **문제 격리**: 각 서비스별 독립적 문제 해결
4. **도구 활용**: `kubectl wait`, 헬스체크를 통한 자동화

#### 주요 교훈
1. **환경 변수 관리**: ConfigMap/Secret 분리의 중요성
2. **이미지 전략**: 개발/프로덕션 환경별 다른 전략 필요
3. **네트워크 정책**: 서비스 간 통신 보안 고려 필요
4. **데이터 영속성**: PV/PVC 백업 전략 수립 필요

#### 피해야 할 실수
1. **동시 마이그레이션**: DB 마이그레이션 동시 실행 방지
2. **리소스 제한 없음**: 무제한 리소스 사용으로 인한 성능 저하
3. **헬스체크 누락**: 서비스 상태 확인 불가
4. **로그 수집 부재**: 문제 진단 어려움

### 📋 체크리스트: 프로덕션 준비도

#### ✅ 완료된 항목
- [x] 마이크로서비스 분리 및 배포
- [x] 서비스 간 통신 구현
- [x] 데이터베이스 멀티 테넌시
- [x] 기본 헬스체크 구현
- [x] 로컬 개발 환경 구축

#### 🔄 진행 중
- [ ] 리소스 제한 및 최적화
- [ ] 보안 정책 적용
- [ ] 모니터링 시스템 구축

#### 📋 향후 계획
- [ ] 운영 환경 배포
- [ ] CI/CD 파이프라인 구축
- [ ] 자동 스케일링 구현
- [ ] 재해 복구 계획 수립

### 💡 권장 사항

#### 새로운 팀을 위한 조언
1. **학습 곡선**: Kubernetes 기본 개념 충분히 학습
2. **환경 분리**: 개발/스테이징/프로덕션 환경 명확히 분리  
3. **도구 활용**: Helm, Kustomize 등 도구 적극 활용
4. **커뮤니티**: Kubernetes 커뮤니티 적극 참여

#### 확장 고려사항
1. **마이크로서비스 증가 시**: Service Mesh (Istio) 도입 검토
2. **트래픽 증가 시**: HPA, VPA, Cluster Autoscaler 활용
3. **다중 클러스터**: Federation, ArgoCD 활용
4. **비용 최적화**: Node pooling, Spot instance 활용

---

## 📚 참고 자료

- [Kubernetes 공식 문서](https://kubernetes.io/docs/)
- [Rails on Kubernetes 모범 사례](https://kubernetes.io/blog/2019/07/23/get-started-with-kubernetes-using-python/)
- [마이크로서비스 패턴](https://microservices.io/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

---

**문서 버전**: v2.0  
**최종 업데이트**: 2025년 9월 1일  
**작성자**: TaskMate 개발팀  
**리뷰어**: Kubernetes Migration Team