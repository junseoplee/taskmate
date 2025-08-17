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

#### 인증 방식
```http
Authorization: Bearer {session_token}
```

#### 공통 응답 형식

**성공 응답**:
```json
{
  "status": "success",
  "data": { ... },
  "message": "Optional success message"
}
```

**에러 응답**:
```json
{
  "status": "error",
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

## 🔐 User Service API

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
  "status": "success",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "사용자 이름",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "session_token": "abc123def456",
  "expires_at": "2024-01-02T00:00:00Z"
}
```

**에러 응답**:
```http
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/json

{
  "status": "error",
  "error": "validation_failed",
  "message": "Validation failed",
  "details": {
    "email": ["has already been taken"],
    "password": ["is too short (minimum is 8 characters)"]
  }
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
  "status": "success",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "사용자 이름",
    "last_login_at": "2024-01-01T00:00:00Z"
  },
  "session_token": "abc123def456",
  "expires_at": "2024-01-02T00:00:00Z"
}
```

**에러 응답**:
```http
HTTP/1.1 401 Unauthorized
Content-Type: application/json

{
  "status": "error",
  "error": "authentication_failed",
  "message": "Invalid email or password"
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
Set-Cookie: session_token=; expires=Thu, 01 Jan 1970 00:00:00 GMT

{
  "status": "success",
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
  "status": "success",
  "valid": true,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "사용자 이름"
  },
  "session": {
    "token": "abc123def456",
    "expires_at": "2024-01-02T00:00:00Z"
  }
}
```

**에러 응답**:
```http
HTTP/1.1 401 Unauthorized
Content-Type: application/json

{
  "status": "error",
  "valid": false,
  "error": "session_expired",
  "message": "Session has expired"
}
```

### 사용자 관리

#### GET /users/profile
사용자 프로필 조회

**요청**:
```http
GET /api/v1/users/profile
Authorization: Bearer abc123def456
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "success",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "사용자 이름",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z",
    "last_login_at": "2024-01-01T12:00:00Z"
  }
}
```

#### PUT /users/profile
사용자 프로필 수정

**요청**:
```http
PUT /api/v1/users/profile
Authorization: Bearer abc123def456
Content-Type: application/json

{
  "user": {
    "name": "새로운 이름",
    "current_password": "SecurePass123!",
    "password": "NewSecurePass123!",
    "password_confirmation": "NewSecurePass123!"
  }
}
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "success",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "새로운 이름",
    "updated_at": "2024-01-01T13:00:00Z"
  },
  "message": "Profile updated successfully"
}
```

#### GET /users/:id
특정 사용자 정보 조회 (내부 API)

**요청**:
```http
GET /api/v1/users/1
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "success",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "사용자 이름",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

### 헬스체크

#### GET /health
서비스 상태 확인

**요청**:
```http
GET /health
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "service": "user-service",
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "version": "1.0.0",
  "dependencies": {
    "database": {
      "status": "healthy",
      "response_time": 15
    },
    "redis": {
      "status": "healthy",
      "response_time": 3
    }
  }
}
```

---

## 📝 Task Service API

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
- `page` (optional): 페이지 번호 (기본값: 1)
- `per_page` (optional): 페이지당 항목 수 (기본값: 20, 최대: 100)
- `sort` (optional): created_at, updated_at, due_date, priority (기본값: created_at)
- `order` (optional): asc, desc (기본값: desc)

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "success",
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
      "updated_at": "2024-01-01T00:00:00Z",
      "overdue": false,
      "days_until_due": 2
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 95,
    "per_page": 20,
    "has_next": true,
    "has_prev": false
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
```http
HTTP/1.1 201 Created
Content-Type: application/json
Location: /api/v1/tasks/2

{
  "status": "success",
  "task": {
    "id": 2,
    "title": "새로운 작업",
    "description": "작업 설명",
    "status": "pending",
    "priority": "medium",
    "due_date": "2024-01-05T00:00:00Z",
    "user_id": 1,
    "created_at": "2024-01-01T12:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z",
    "overdue": false,
    "days_until_due": 4
  },
  "message": "Task created successfully"
}
```

**에러 응답**:
```http
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/json

{
  "status": "error",
  "error": "validation_failed",
  "message": "Validation failed",
  "details": {
    "title": ["can't be blank"],
    "due_date": ["must be in the future"]
  }
}
```

#### GET /tasks/:id
특정 태스크 조회

**요청**:
```http
GET /api/v1/tasks/1
Authorization: Bearer abc123def456
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "success",
  "task": {
    "id": 1,
    "title": "중요한 작업",
    "description": "작업 설명",
    "status": "pending",
    "priority": "high",
    "due_date": "2024-01-03T00:00:00Z",
    "user_id": 1,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z",
    "overdue": false,
    "days_until_due": 2
  }
}
```

#### PUT /tasks/:id
태스크 전체 수정

**요청**:
```http
PUT /api/v1/tasks/1
Authorization: Bearer abc123def456
Content-Type: application/json

{
  "task": {
    "title": "수정된 작업",
    "description": "수정된 설명",
    "priority": "urgent",
    "due_date": "2024-01-04T00:00:00Z"
  }
}
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "success",
  "task": {
    "id": 1,
    "title": "수정된 작업",
    "description": "수정된 설명",
    "status": "pending",
    "priority": "urgent",
    "due_date": "2024-01-04T00:00:00Z",
    "user_id": 1,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T13:00:00Z",
    "overdue": false,
    "days_until_due": 3
  },
  "message": "Task updated successfully"
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
  "status": "in_progress"
}
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "success",
  "task": {
    "id": 1,
    "title": "수정된 작업",
    "description": "수정된 설명",
    "status": "in_progress",
    "priority": "urgent",
    "due_date": "2024-01-04T00:00:00Z",
    "user_id": 1,
    "started_at": "2024-01-01T13:30:00Z",
    "updated_at": "2024-01-01T13:30:00Z"
  },
  "message": "Task status updated to in_progress"
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

### 헬스체크

#### GET /health
서비스 상태 확인

**요청**:
```http
GET /health
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "service": "task-service",
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "version": "1.0.0",
  "dependencies": {
    "database": {
      "status": "healthy",
      "response_time": 18
    },
    "redis": {
      "status": "healthy",
      "response_time": 5
    },
    "user_service": {
      "status": "healthy",
      "response_time": 45
    }
  }
}
```

---

## 📊 Analytics Service API

**구현 상태**: 기본 구조 완료, 통계 API 구현 예정

### 서비스 상태 확인

#### GET /health
서비스 상태 확인

**요청**:
```http
GET /api/v1/health
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "service": "analytics-service",
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "version": "1.0.0",
  "dependencies": {
    "database": {
      "status": "healthy",
      "response_time": 12
    },
    "redis": {
      "status": "healthy",
      "response_time": 3
    },
    "user_service": {
      "status": "healthy",
      "response_time": 35
    }
  }
}
```

### 통계 데이터 (구현 예정)

아래 API들은 Phase 4에서 구현 예정입니다:

#### GET /analytics/dashboard (예정)
대시보드 통계 데이터

**요청**:
```http
GET /api/v1/analytics/dashboard?period=30d
Authorization: Bearer abc123def456
```

**쿼리 파라미터**:
- `period` (optional): 1d, 7d, 30d, 90d (기본값: 30d)
- `user_id` (optional): 특정 사용자 통계 (관리자만)

#### GET /analytics/tasks/completion-rate (예정)
완료율 통계

**요청**:
```http
GET /api/v1/analytics/tasks/completion-rate?period=7d&group_by=day
Authorization: Bearer abc123def456
```

#### POST /analytics/events (예정)
이벤트 수신 (내부 API)

**요청**:
```http
POST /api/v1/analytics/events
Content-Type: application/json

{
  "event": {
    "type": "task_created",
    "user_id": 1,
    "task_id": 15,
    "timestamp": "2024-01-01T12:00:00Z"
  }
}
```

---

## 📎 File Service API

**구현 상태**: 기본 구조 완료, 파일 관리 API 구현 완료

### 파일 카테고리 관리

#### GET /file_categories
파일 카테고리 목록 조회

**요청**:
```http
GET /api/v1/file_categories
Authorization: Bearer abc123def456
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "success",
  "file_categories": [
    {
      "id": 1,
      "name": "문서",
      "description": "일반 문서 파일",
      "max_file_size": 10485760,
      "allowed_extensions": [".pdf", ".doc", ".docx"],
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    },
    {
      "id": 2,
      "name": "이미지",
      "description": "이미지 파일",
      "max_file_size": 5242880,
      "allowed_extensions": [".jpg", ".jpeg", ".png", ".gif"],
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
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
    "name": "비디오",
    "description": "동영상 파일",
    "max_file_size": 52428800,
    "allowed_extensions": [".mp4", ".avi", ".mov"]
  }
}
```

**응답**:
```http
HTTP/1.1 201 Created
Content-Type: application/json

{
  "status": "success",
  "file_category": {
    "id": 3,
    "name": "비디오",
    "description": "동영상 파일",
    "max_file_size": 52428800,
    "allowed_extensions": [".mp4", ".avi", ".mov"],
    "created_at": "2024-01-01T12:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z"
  },
  "message": "File category created successfully"
}
```

### 파일 첨부 관리

#### GET /file_attachments
파일 첨부 목록 조회

**요청**:
```http
GET /api/v1/file_attachments?page=1&per_page=20
Authorization: Bearer abc123def456
```

**쿼리 파라미터**:
- `page` (optional): 페이지 번호 (기본값: 1)
- `per_page` (optional): 페이지당 항목 수 (기본값: 20)
- `category_id` (optional): 카테고리 필터

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "success",
  "file_attachments": [
    {
      "id": 1,
      "filename": "document.pdf",
      "file_size": 2048576,
      "content_type": "application/pdf",
      "file_category_id": 1,
      "user_id": 1,
      "task_id": null,
      "file_path": "/uploads/documents/document.pdf",
      "checksum": "abc123def456",
      "created_at": "2024-01-01T12:00:00Z",
      "updated_at": "2024-01-01T12:00:00Z"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 1,
    "total_count": 1,
    "per_page": 20
  }
}
```

#### POST /file_attachments
파일 업로드

**요청**:
```http
POST /api/v1/file_attachments
Authorization: Bearer abc123def456
Content-Type: multipart/form-data

file: [binary data]
file_category_id: 1
task_id: 15
```

**응답**:
```http
HTTP/1.1 201 Created
Content-Type: application/json

{
  "status": "success",
  "file_attachment": {
    "id": 2,
    "filename": "important_document.pdf",
    "file_size": 1024768,
    "content_type": "application/pdf",
    "file_category_id": 1,
    "user_id": 1,
    "task_id": 15,
    "file_path": "/uploads/documents/important_document.pdf",
    "checksum": "def456abc789",
    "created_at": "2024-01-01T13:00:00Z",
    "updated_at": "2024-01-01T13:00:00Z"
  },
  "message": "File uploaded successfully"
}
```

#### GET /file_attachments/:id
파일 다운로드

**요청**:
```http
GET /api/v1/file_attachments/1
Authorization: Bearer abc123def456
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/pdf
Content-Disposition: attachment; filename="document.pdf"
Content-Length: 2048576

[binary data]
```

#### DELETE /file_attachments/:id
파일 삭제

**요청**:
```http
DELETE /api/v1/file_attachments/1
Authorization: Bearer abc123def456
```

**응답**:
```http
HTTP/1.1 204 No Content
```

### 서비스 상태 확인

#### GET /health
서비스 상태 확인

**요청**:
```http
GET /api/v1/health
```

**응답**:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "service": "file-service",
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "version": "1.0.0",
  "dependencies": {
    "database": {
      "status": "healthy",
      "response_time": 15
    },
    "redis": {
      "status": "healthy",
      "response_time": 4
    },
    "user_service": {
      "status": "healthy",
      "response_time": 42
    },
    "storage": {
      "status": "healthy",
      "available_space": "95%"
    }
  }
}
```

---

## 🔗 서비스 간 통신

### 내부 API 호출 패턴

#### Task Service → User Service
```http
GET /api/v1/auth/verify
Authorization: Bearer {session_token}

# 응답으로 사용자 정보 확인
```

#### Analytics Service ← Task Service
```http
POST /api/v1/analytics/events
Content-Type: application/json

{
  "event": {
    "type": "task_status_changed",
    "user_id": 1,
    "task_id": 15,
    "from_status": "pending",
    "to_status": "completed",
    "timestamp": "2024-01-01T12:00:00Z"
  }
}
```

#### File Service → User Service
```http
GET /api/v1/auth/verify
Authorization: Bearer {session_token}

# 파일 업로드/다운로드 시 인증 확인
```

### 에러 처리

#### 서비스 이용 불가
```http
HTTP/1.1 503 Service Unavailable
Content-Type: application/json

{
  "status": "error",
  "error": "service_unavailable",
  "message": "User service is temporarily unavailable",
  "retry_after": 30
}
```

#### 인증 서비스 오류
```http
HTTP/1.1 502 Bad Gateway
Content-Type: application/json

{
  "status": "error",
  "error": "authentication_service_error", 
  "message": "Unable to verify authentication",
  "fallback": "Please login again"
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
  "password_digest": "string (hashed)",
  "created_at": "datetime",
  "updated_at": "datetime",
  "last_login_at": "datetime"
}
```

#### Session
```json
{
  "id": "integer",
  "user_id": "integer (foreign key)",
  "token": "string (uuid, unique)",
  "expires_at": "datetime",
  "created_at": "datetime",
  "updated_at": "datetime"
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
  "started_at": "datetime",
  "completed_at": "datetime"
}
```

### Analytics Service

#### Event (구현 예정)
```json
{
  "id": "integer",
  "type": "string",
  "user_id": "integer",
  "entity_type": "string",
  "entity_id": "integer",
  "metadata": "jsonb",
  "timestamp": "datetime",
  "processed_at": "datetime"
}
```

### File Service

#### FileCategory
```json
{
  "id": "integer",
  "name": "string (unique)",
  "description": "text",
  "max_file_size": "integer (bytes)",
  "allowed_extensions": "array of strings",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

#### FileAttachment
```json
{
  "id": "integer",
  "filename": "string",
  "file_size": "integer (bytes)",
  "content_type": "string",
  "file_category_id": "integer (foreign key)",
  "user_id": "integer",
  "task_id": "integer (nullable)",
  "file_path": "string",
  "checksum": "string (SHA256)",
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
- **파일 업로드**: 파일 타입, 크기 제한
- **Rate Limiting**: API 호출 빈도 제한

### 데이터 보호
- **민감 정보 마스킹**: 로그에서 패스워드, 토큰 제외
- **HTTPS 강제**: 모든 API 통신 암호화
- **데이터베이스 암호화**: 민감 정보 필드 암호화

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
      "password": "SecurePass123!",
      "password_confirmation": "SecurePass123!"
    }
  }'

# 로그인
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com", 
      "password": "SecurePass123!"
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
```

#### Postman Collection
```json
{
  "info": {
    "name": "TaskMate API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    {
      "key": "user_service_url",
      "value": "http://localhost:3000"
    },
    {
      "key": "task_service_url", 
      "value": "http://localhost:3001"
    },
    {
      "key": "session_token",
      "value": ""
    }
  ],
  "item": [
    {
      "name": "Auth",
      "item": [
        {
          "name": "Register",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"user\": {\n    \"email\": \"{{$randomEmail}}\",\n    \"name\": \"{{$randomFullName}}\",\n    \"password\": \"SecurePass123!\",\n    \"password_confirmation\": \"SecurePass123!\"\n  }\n}"
            },
            "url": {
              "raw": "{{user_service_url}}/api/v1/auth/register",
              "host": ["{{user_service_url}}"],
              "path": ["api", "v1", "auth", "register"]
            }
          },
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "if (pm.response.code === 201) {",
                  "  const response = pm.response.json();",
                  "  pm.collectionVariables.set('session_token', response.session_token);",
                  "}"
                ]
              }
            }
          ]
        }
      ]
    }
  ]
}
```

### 성능 테스트

#### Apache Bench 예제
```bash
# 인증 API 부하 테스트
ab -n 1000 -c 10 -H "Content-Type: application/json" \
   -p login_data.json \
   http://localhost:3000/api/v1/auth/login

# 태스크 목록 API 부하 테스트  
ab -n 1000 -c 10 -H "Authorization: Bearer {token}" \
   http://localhost:3001/api/v1/tasks
```

---

## 📋 API 변경 이력

### v1.0.0 (2024-01-01)
- 초기 API 버전
- User Service: 기본 인증 기능 완료
- Task Service: CRUD 기능 완료
- Analytics Service: 기본 구조 완료 (통계 API 구현 예정)
- File Service: 파일 관리 API 기본 기능 완룼

### 향후 계획

#### v1.1.0 (예정)
- [ ] API Rate Limiting 추가
- [ ] WebSocket 실시간 알림
- [ ] 파일 업로드 진행률 API
- [ ] 태스크 댓글 기능

#### v1.2.0 (예정)
- [ ] GraphQL API 지원
- [ ] API 키 기반 인증
- [ ] 대시보드 실시간 업데이트
- [ ] 파일 미리보기 API

이 API 명세서는 TaskMate 마이크로서비스의 모든 엔드포인트와 사용법을 포함하고 있으며, 개발 과정에서 지속적으로 업데이트됩니다.