# TaskMate API 명세서

TaskMate 마이크로서비스 아키텍처의 RESTful API 명세서입니다.

## 📋 개요

### API 설계 원칙
- **RESTful**: HTTP 메서드와 상태 코드를 적절히 활용
- **일관성**: 모든 서비스에서 동일한 응답 형식 사용
- **버전 관리**: `/api/v1/` 접두사로 API 버전 관리
- **보안**: 세션 기반 인증 및 권한 검증
- **에러 처리**: 명확하고 일관된 에러 응답

### 공통 사항

#### Base URL
- **User Service**: `http://localhost:3000/api/v1`
- **Task Service**: `http://localhost:3001/api/v1`
- **Analytics Service**: `http://localhost:3002/api/v1`
- **File Service**: `http://localhost:3003/api/v1`
- **Frontend Service**: `http://localhost:3100` (Web UI)

#### 인증 방식
```http
Authorization: Bearer {session_token}
```

#### 공통 응답 형식

**성공 응답**:
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional success message"
}
```

**에러 응답**:
```json
{
  "success": false,
  "error": "Error type",
  "message": "Human readable error message",
  "details": { ... }
}
```

#### HTTP 상태 코드
- `200` OK - 성공적인 GET, PUT 요청
- `201` Created - 성공적인 POST 요청
- `204` No Content - 성공적인 DELETE 요청
- `400` Bad Request - 잘못된 요청 형식
- `401` Unauthorized - 인증 실패
- `403` Forbidden - 권한 없음
- `404` Not Found - 리소스 없음
- `422` Unprocessable Entity - 유효성 검증 실패
- `500` Internal Server Error - 서버 오류
- `503` Service Unavailable - 서비스 이용 불가

---

## 🔐 User Service API (100% 구현 완료)

### 인증 관리

#### POST /auth/register
사용자 회원가입

**요청**:
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "name": "사용자 이름",
    "password": "SecurePass123!",
    "password_confirmation": "SecurePass123!"
  }
}
```

**응답**:
```http
HTTP/1.1 201 Created
Content-Type: application/json
Set-Cookie: session_token=abc123; HttpOnly; Secure; SameSite=Strict

{
  "success": true,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "사용자 이름",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "session_token": "abc123def456"
}
```

#### POST /auth/login
사용자 로그인

**요청**:
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "password": "SecurePass123!"
  }
}
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json
Set-Cookie: session_token=abc123; HttpOnly; Secure; SameSite=Strict

{
  "success": true,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "사용자 이름"
  },
  "session_token": "abc123def456"
}
```

#### POST /auth/logout
사용자 로그아웃

**요청**:
```http
POST /api/v1/auth/logout
Authorization: Bearer abc123def456
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "message": "Successfully logged out"
}
```

#### GET /auth/verify
세션 검증 (다른 서비스용 내부 API)

**요청**:
```http
GET /api/v1/auth/verify
Authorization: Bearer abc123def456
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "valid": true,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "사용자 이름"
  }
}
```

---

## 📝 Task Service API (100% 구현 완료)

### 태스크 관리

#### GET /tasks
태스크 목록 조회

**요청**:
```http
GET /api/v1/tasks?status=pending&priority=high&page=1&per_page=20
Authorization: Bearer abc123def456
```

**쿼리 파라미터**:
- `status` (optional): pending, in_progress, completed, cancelled
- `priority` (optional): low, medium, high, urgent
- `overdue` (optional): true/false - 기한 지난 태스크만
- `due_soon` (optional): true/false - 곧 마감되는 태스크만
- `page` (optional): 페이지 번호 (기본값: 1)
- `per_page` (optional): 페이지당 항목 수 (기본값: 20)

**응답**:
```json
{
  "success": true,
  "data": {
    "tasks": [
      {
        "id": 1,
        "title": "중요한 작업",
        "description": "작업 설명",
        "status": "pending",
        "priority": "high",
        "due_date": "2024-01-03T00:00:00Z",
        "user_id": 1,
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T00:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_count": 95
    }
  }
}
```

#### POST /tasks
새 태스크 생성

**요청**:
```http
POST /api/v1/tasks
Authorization: Bearer abc123def456
Content-Type: application/json

{
  "task": {
    "title": "새로운 작업",
    "description": "작업 설명",
    "priority": "medium",
    "due_date": "2024-01-05T00:00:00Z"
  }
}
```

**응답**:
```json
{
  "success": true,
  "data": {
    "task": {
      "id": 2,
      "title": "새로운 작업",
      "description": "작업 설명",
      "status": "pending",
      "priority": "medium",
      "due_date": "2024-01-05T00:00:00Z",
      "user_id": 1
    }
  },
  "message": "Task created successfully"
}
```

#### GET /tasks/:id
특정 태스크 조회

**요청**:
```http
GET /api/v1/tasks/1
Authorization: Bearer abc123def456
```

#### PUT /tasks/:id
태스크 수정

**요청**:
```http
PUT /api/v1/tasks/1
Authorization: Bearer abc123def456
Content-Type: application/json

{
  "task": {
    "title": "수정된 작업",
    "description": "수정된 설명",
    "priority": "urgent"
  }
}
```

#### PATCH /tasks/:id/status
태스크 상태 변경

**요청**:
```http
PATCH /api/v1/tasks/1/status
Authorization: Bearer abc123def456
Content-Type: application/json

{
  "status": "completed"
}
```

#### DELETE /tasks/:id
태스크 삭제

**요청**:
```http
DELETE /api/v1/tasks/1
Authorization: Bearer abc123def456
```

**응답**:
```http
HTTP/1.1 204 No Content
```

---

## 📊 Analytics Service API (100% 구현 완료)

### 통계 데이터

#### GET /analytics/dashboard
대시보드 통계 데이터

**요청**:
```http
GET /api/v1/analytics/dashboard?user_id=1&days=30
Authorization: Bearer abc123def456
```

**응답**:
```json
{
  "success": true,
  "data": {
    "statistics": {
      "total_tasks": 127,
      "completed_tasks": 85,
      "completion_rate": 66.93,
      "pending_tasks": 30,
      "in_progress_tasks": 12,
      "average_completion_time": 2.5
    }
  }
}
```

#### GET /analytics/tasks/completion-rate
완료율 통계

**요청**:
```http
GET /api/v1/analytics/tasks/completion-rate?user_id=1
Authorization: Bearer abc123def456
```

**응답**:
```json
{
  "success": true,
  "data": {
    "completion_rate": 66.93,
    "total_tasks": 127,
    "completed_tasks": 85
  }
}
```

#### GET /analytics/completion-trend
완료 추세 데이터

**요청**:
```http
GET /api/v1/analytics/completion-trend?user_id=1&days=7
Authorization: Bearer abc123def456
```

**응답**:
```json
{
  "success": true,
  "data": {
    "trend": [
      {"date": "2024-01-01", "completed": 3},
      {"date": "2024-01-02", "completed": 5},
      {"date": "2024-01-03", "completed": 2}
    ]
  }
}
```

#### GET /analytics/priority-distribution
우선순위별 태스크 분포

**요청**:
```http
GET /api/v1/analytics/priority-distribution?user_id=1
Authorization: Bearer abc123def456
```

**응답**:
```json
{
  "success": true,
  "data": {
    "distribution": {
      "high": 8,
      "medium": 12,
      "low": 4,
      "urgent": 1
    },
    "total": 25
  }
}
```

#### POST /analytics/events
이벤트 수신 (내부 API)

**요청**:
```http
POST /api/v1/analytics/events
Content-Type: application/json

{
  "event": {
    "event_type": "task_created",
    "user_id": 1,
    "task_id": 15,
    "data": {}
  }
}
```

#### GET /health
서비스 상태 확인

**요청**:
```http
GET /api/v1/health
```

**응답**:
```json
{
  "status": "healthy",
  "service": "analytics-service",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

---

## 📎 File Service API (100% 구현 완료)

### Simple Files API (주요 사용)

#### GET /simple_files
Simple Files 목록 조회

**요청**:
```http
GET /api/v1/simple_files?user_id=1&page=1&per_page=20
Authorization: Bearer abc123def456
```

**응답**:
```json
{
  "data": {
    "files": [
      {
        "id": 1,
        "filename": "document.pdf",
        "file_url": "https://example.com/files/document.pdf",
        "file_type": "document",
        "file_category_id": 1,
        "created_at": "2024-01-01T12:00:00Z",
        "file_category": {
          "id": 1,
          "name": "Documents"
        }
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total_count": 5,
      "total_pages": 1
    }
  }
}
```

#### POST /simple_files
Simple File 생성 (URL 기반)

**요청**:
```http
POST /api/v1/simple_files
Authorization: Bearer abc123def456
Content-Type: application/json

{
  "simple_file": {
    "filename": "report.pdf",
    "file_url": "https://example.com/files/report.pdf",
    "file_type": "document",
    "file_category_id": 1,
    "user_id": 1
  }
}
```

**응답**:
```json
{
  "success": true,
  "data": {
    "file": {
      "id": 2,
      "filename": "report.pdf",
      "file_url": "https://example.com/files/report.pdf",
      "file_type": "document",
      "file_category_id": 1,
      "created_at": "2024-01-01T13:00:00Z"
    }
  }
}
```

#### DELETE /simple_files/:id
Simple File 삭제

**요청**:
```http
DELETE /api/v1/simple_files/1
Authorization: Bearer abc123def456
```

**응답**:
```http
HTTP/1.1 204 No Content
```

#### GET /simple_files/statistics
파일 통계 조회

**요청**:
```http
GET /api/v1/simple_files/statistics?user_id=1
Authorization: Bearer abc123def456
```

**응답**:
```json
{
  "data": {
    "statistics": {
      "total_files": 5,
      "by_type": {
        "document": 3,
        "image": 2
      },
      "by_category": {
        "Documents": 3,
        "Images": 2
      },
      "recent_files": [...]
    }
  }
}
```

### 파일 카테고리 관리

#### GET /file_categories
파일 카테고리 목록 조회

**요청**:
```http
GET /api/v1/file_categories?user_id=1
Authorization: Bearer abc123def456
```

**응답**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Documents",
      "description": "Document files",
      "max_file_size": 10485760,
      "files_count": 3,
      "total_size": 5242880
    },
    {
      "id": 2,
      "name": "Images",
      "description": "Image files",
      "max_file_size": 5242880,
      "files_count": 2,
      "total_size": 2097152
    }
  ]
}
```

#### POST /file_categories
새 파일 카테고리 생성

**요청**:
```http
POST /api/v1/file_categories
Authorization: Bearer abc123def456
Content-Type: application/json

{
  "file_category": {
    "name": "Videos",
    "description": "Video files",
    "max_file_size": 52428800,
    "user_id": 1
  }
}
```

### Legacy File Attachments API (하위 호환성)

#### GET /file_attachments
파일 첨부 목록 조회

#### POST /file_attachments
파일 업로드

#### GET /file_attachments/:id
파일 다운로드

#### DELETE /file_attachments/:id
파일 삭제

---

## 🖥️ Frontend Service (100% 구현 완료)

Frontend Service는 Rails Views 기반의 웹 UI를 제공하며, 백엔드 마이크로서비스들과 API Gateway 패턴으로 통합됩니다.

### 주요 기능

#### 인증 관리
- `/login` - 로그인 페이지
- `/register` - 회원가입 페이지
- `/logout` - 로그아웃 처리

#### 대시보드
- `/dashboard` - 메인 대시보드 (통계 요약)
- `/` - 홈 페이지 (로그인 후 대시보드로 리다이렉트)

#### 태스크 관리
- `/tasks` - 태스크 목록
- `/tasks/new` - 새 태스크 생성
- `/tasks/:id` - 태스크 상세 보기
- `/tasks/:id/edit` - 태스크 수정
- `/tasks/overdue` - 기한 지난 태스크
- `/tasks/upcoming` - 다가오는 태스크
- `/tasks/search` - 태스크 검색
- `/tasks/statistics` - 태스크 통계

#### 통계 분석
- `/analytics` - 통계 대시보드
  - 태스크 완료율
  - 우선순위 분포
  - 완료 트렌드
  - Time Period 필터링 (7, 30, 90, 365일)
  - 실시간 새로고침 기능

#### 파일 관리
- `/files` - 파일 목록
- `/files/add_url` - URL 기반 파일 추가
- 파일 카테고리별 필터링
- 파일 삭제 기능

### Service Client 구조

Frontend Service는 다음의 Service Client를 통해 백엔드와 통신합니다:

- **UserServiceClient** - User Service 연동 (인증/세션)
- **TaskServiceClient** - Task Service 연동 (태스크 CRUD)
- **AnalyticsServiceClient** - Analytics Service 연동 (통계)
- **FileServiceClient** - File Service 연동 (Simple Files API)

### 세션 관리

모든 백엔드 API 호출 시 세션 토큰이 자동으로 전달되며, 다음과 같이 처리됩니다:

```ruby
session_token: current_session_token  # 모든 Service Client 메서드에 전달
```

### UI 특징

- **Tailwind CSS** 기반 반응형 디자인
- **Flash 메시지** 시스템 (성공/오류 알림)
- **네비게이션 바** (로그인 상태 표시)
- **모바일 친화적** 레이아웃
- **실시간 업데이트** (JavaScript)

---

## 🔗 서비스 간 통신

### 내부 API 호출 패턴

#### Task Service → User Service
```http
GET /api/v1/auth/verify
Authorization: Bearer {session_token}
```

#### Analytics Service → User Service
```http
GET /api/v1/auth/verify
Authorization: Bearer {session_token}
```

#### File Service → User Service
```http
GET /api/v1/auth/verify
Authorization: Bearer {session_token}
```

#### Frontend Service → All Backend Services
Frontend Service는 각 백엔드 서비스의 모든 API를 Service Client를 통해 호출합니다.

### 에러 처리

#### 서비스 이용 불가
```json
{
  "success": false,
  "error": "service_unavailable",
  "message": "User service is temporarily unavailable",
  "retry_after": 30
}
```

#### 인증 실패
```json
{
  "success": false,
  "error": "authentication_failed",
  "message": "Invalid or expired session token"
}
```

---

## 📝 데이터 모델

### User Service

#### User
```json
{
  "id": "integer",
  "email": "string (unique)",
  "name": "string",
  "password_digest": "string (BCrypt hashed)",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

#### Session
```json
{
  "id": "integer",
  "user_id": "integer (foreign key)",
  "token": "string (UUID, unique)",
  "expires_at": "datetime",
  "created_at": "datetime"
}
```

### Task Service

#### Task
```json
{
  "id": "integer",
  "title": "string",
  "description": "text",
  "status": "enum (pending, in_progress, completed, cancelled)",
  "priority": "enum (low, medium, high, urgent)",
  "due_date": "datetime",
  "user_id": "integer",
  "created_at": "datetime",
  "updated_at": "datetime",
  "completed_at": "datetime (nullable)"
}
```

### Analytics Service

#### TaskAnalytics
```json
{
  "id": "integer",
  "user_id": "integer",
  "task_id": "integer",
  "event_type": "string",
  "data": "jsonb",
  "created_at": "datetime"
}
```

#### UserAnalytics
```json
{
  "id": "integer",
  "user_id": "integer",
  "metrics": "jsonb",
  "period": "string",
  "created_at": "datetime"
}
```

### File Service

#### SimpleFile
```json
{
  "id": "integer",
  "filename": "string",
  "file_url": "string (URL)",
  "file_type": "string",
  "file_category_id": "integer",
  "user_id": "integer",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

#### FileCategory
```json
{
  "id": "integer",
  "name": "string",
  "description": "text",
  "max_file_size": "integer (bytes)",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

---

## 🔐 보안 고려사항

### 인증 및 인가
- **세션 토큰**: UUID 기반, 24시간 TTL
- **쿠키 보안**: HttpOnly, Secure, SameSite=Strict
- **패스워드**: BCrypt 해싱, 최소 8자리
- **권한 검증**: 각 API에서 리소스 소유권 확인

### 입력 검증
- **XSS 방지**: 모든 사용자 입력 이스케이프
- **SQL Injection 방지**: 파라미터화된 쿼리 사용
- **파일 업로드**: URL 검증 (Simple Files API)
- **Rate Limiting**: API 호출 빈도 제한

### 데이터 보호
- **민감 정보 마스킹**: 로그에서 패스워드, 토큰 제외
- **HTTPS 강제**: 프로덕션 환경에서 모든 API 통신 암호화
- **세션 관리**: 자동 만료 및 정리

---

## 🧪 테스트

### API 테스트 예제

#### cURL 예제
```bash
# 회원가입
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

# 로그인
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123"
    }
  }'

# 태스크 생성
curl -X POST http://localhost:3001/api/v1/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {session_token}" \
  -d '{
    "task": {
      "title": "테스트 태스크",
      "description": "API 테스트용 태스크",
      "priority": "medium",
      "due_date": "2024-01-05T00:00:00Z"
    }
  }'

# Simple File 생성
curl -X POST http://localhost:3003/api/v1/simple_files \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {session_token}" \
  -d '{
    "simple_file": {
      "filename": "test.pdf",
      "file_url": "https://example.com/test.pdf",
      "file_type": "document",
      "file_category_id": 1,
      "user_id": 1
    }
  }'
```

### Docker Compose 통합 테스트

```bash
# 모든 서비스 시작
docker-compose up -d

# 서비스 상태 확인
docker-compose ps

# 통합 테스트 실행
curl http://localhost:3000/api/v1/health  # User Service
curl http://localhost:3001/api/v1/health  # Task Service
curl http://localhost:3002/api/v1/health  # Analytics Service
curl http://localhost:3003/api/v1/health  # File Service

# Frontend UI 접속
open http://localhost:3100
```

---

## 📊 구현 현황 (2025-08-28)

| 서비스 | API 수 | 구현률 | 테스트 | 상태 |
|--------|--------|--------|--------|------|
| **User Service** | 4/4 | 100% | 53개 통과 | ✅ 완료 |
| **Task Service** | 6/6 | 100% | 39개 통과 | ✅ 완료 |
| **Analytics Service** | 6/6 | 100% | 30개 통과 | ✅ 완료 |
| **File Service** | 10/10 | 100% | 45개 통과 | ✅ 완료 |
| **Frontend Service** | - | 100% | 6개 통과 | ✅ 완료 |

### 주요 변경사항 (2025-08-28)

#### File Service
- Simple Files API 추가 (URL 기반 파일 관리)
- FileAttachment API를 Legacy로 전환
- 파일 통계 API 구현

#### Frontend Service
- Session Token 인증 플로우 완전 구현
- 파일 삭제 기능 수정 (delete_simple_file 메서드 사용)
- Analytics Time Period 레이아웃 개선

#### Analytics Service
- 모든 통계 API 완전 구현
- 대시보드, 완료율, 트렌드, 우선순위 분포 API

---

이 API 명세서는 TaskMate 마이크로서비스의 모든 엔드포인트와 사용법을 포함하고 있으며, 모든 핵심 기능이 100% 구현 완료되었습니다.