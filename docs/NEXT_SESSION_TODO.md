# 📋 Next Session TODO - Frontend Service 인증 이슈 해결

## 🚨 현재 문제 상황

### 주요 이슈: Session Token 전달 오류
- **증상**: 로그인 후 태스크 생성 시 "Access denied" 오류 발생
- **원인**: TasksController의 create action에서 session_token이 TaskServiceClient에 전달되지 않음
- **영향**: 태스크 생성, 수정, 삭제 기능 모두 작동 불가

### 테스트 결과
- ✅ Analytics 페이지: 정상 작동 (데이터 127개 표시)
- ❌ Tasks 페이지: "No tasks found" 표시 (실제로는 17개 태스크 존재)
- ❌ Task 생성: "Access denied" 오류

## 🔍 다른 서비스들의 구현 패턴 분석

### 1. Analytics Service 구현 (✅ 정상 작동)

**파일**: `services/frontend-service/app/controllers/analytics_controller.rb`
```ruby
def index
  analytics_client = AnalyticsServiceClient.new
  
  # ✅ 올바른 패턴: session_token을 명시적으로 전달
  @dashboard_data = analytics_client.get_dashboard_stats(
    current_user['id'], 
    session_token: session[:session_token]
  )
  
  @completion_rate = analytics_client.get_completion_rate(
    current_user['id'],
    session_token: session[:session_token]
  )
end
```

**Service Client**: `services/frontend-service/app/services/analytics_service_client.rb`
```ruby
def get_dashboard_stats(user_id, options = {})
  session_token = options.delete(:session_token)
  
  headers = { 
    'X-User-ID' => user_id.to_s,
    'Content-Type' => 'application/json'
  }
  
  # ✅ Bearer token을 Authorization 헤더에 추가
  headers['Authorization'] = "Bearer #{session_token}" if session_token
  
  make_request(:get, "/api/v1/analytics/dashboard", { headers: headers })
end
```

### 2. Task Service 구현 (❌ 문제 있음)

**현재 문제가 있는 코드**: `services/frontend-service/app/controllers/tasks_controller.rb`
```ruby
def create
  task_client = TaskServiceClient.new
  task_data = task_params.to_h
  
  # ❌ 문제: session_token이 전달되지 않음!
  result = task_client.create_task(current_user['id'], task_data)
  # 수정 필요: session_token: session[:session_token] 추가
  
  if result['success']
    redirect_to tasks_path, notice: 'Task created successfully'
  else
    flash.now[:alert] = result['message'] || 'Failed to create task'
    render :new
  end
end
```

### 3. Backend Service 인증 검증 패턴

**User Service의 세션 검증**: `services/user-service/app/controllers/api/v1/auth_controller.rb`
```ruby
def verify
  # Bearer token 추출
  token = extract_token_from_header
  
  return render_unauthorized('No token provided') unless token
  
  session = Session.active.find_by(token: token)
  
  if session && session.active?
    render json: { 
      success: true, 
      user: UserSerializer.new(session.user).as_json 
    }
  else
    render_unauthorized('Invalid or expired session')
  end
end

private

def extract_token_from_header
  auth_header = request.headers['Authorization']
  return nil unless auth_header.present?
  
  # "Bearer <token>" 형식에서 토큰 추출
  auth_header.split(' ').last if auth_header.start_with?('Bearer ')
end
```

**Task Service의 인증 체크**: `services/task-service/app/controllers/application_controller.rb`
```ruby
before_action :authenticate_user!

def authenticate_user!
  token = extract_bearer_token
  
  unless token && verify_session_with_user_service(token)
    render json: { 
      success: false, 
      message: 'Access denied' 
    }, status: :unauthorized
  end
end
```

## 🛠️ 해결 방안 (Step by Step)

### Step 1: TasksController#create 수정
**파일**: `services/frontend-service/app/controllers/tasks_controller.rb`

```ruby
def create
  task_client = TaskServiceClient.new
  task_data = task_params.to_h
  
  # ✅ 수정: session_token 전달 추가
  result = task_client.create_task(
    current_user['id'], 
    task_data,
    session_token: session[:session_token]  # 이 부분 추가!
  )
  
  if result['success']
    redirect_to tasks_path, notice: 'Task created successfully'
  else
    flash.now[:alert] = result['message'] || 'Failed to create task'
    render :new
  end
end
```

### Step 2: TasksController#update 수정
```ruby
def update
  task_client = TaskServiceClient.new
  
  # ✅ 수정: session_token 전달 추가
  result = task_client.update_task(
    params[:id], 
    task_params.to_h,
    session_token: session[:session_token]  # 이 부분 추가!
  )
  
  if result['success']
    redirect_to task_path(params[:id]), notice: 'Task updated successfully'
  else
    flash.now[:alert] = result['message'] || 'Failed to update task'
    render :edit
  end
end
```

### Step 3: TasksController#destroy 수정
```ruby
def destroy
  task_client = TaskServiceClient.new
  
  # ✅ 수정: session_token 전달 추가
  result = task_client.delete_task(
    params[:id],
    session_token: session[:session_token]  # 이 부분 추가!
  )
  
  if result['success']
    redirect_to tasks_path, notice: 'Task deleted successfully'
  else
    redirect_to tasks_path, alert: result['message'] || 'Failed to delete task'
  end
end
```

### Step 4: TaskServiceClient 메서드 확인
**파일**: `services/frontend-service/app/services/task_service_client.rb`

이미 구현되어 있어야 할 패턴:
```ruby
def create_task(user_id, task_data, options = {})
  session_token = options.delete(:session_token)
  
  headers = { 
    'X-User-ID' => user_id.to_s,
    'Content-Type' => 'application/json'
  }
  
  # Bearer token 추가
  headers['Authorization'] = "Bearer #{session_token}" if session_token
  
  payload = { task: task_data }
  make_request(:post, "/api/v1/tasks", { 
    headers: headers, 
    body: payload.to_json 
  })
end

def update_task(task_id, task_data, options = {})
  session_token = options.delete(:session_token)
  
  headers = { 
    'Content-Type' => 'application/json'
  }
  
  headers['Authorization'] = "Bearer #{session_token}" if session_token
  
  payload = { task: task_data }
  make_request(:put, "/api/v1/tasks/#{task_id}", { 
    headers: headers, 
    body: payload.to_json 
  })
end

def delete_task(task_id, options = {})
  session_token = options.delete(:session_token)
  
  headers = {}
  headers['Authorization'] = "Bearer #{session_token}" if session_token
  
  make_request(:delete, "/api/v1/tasks/#{task_id}", { 
    headers: headers 
  })
end
```

## 🧪 테스트 방법

### 1. 수동 테스트
```bash
# 1. Docker Compose로 모든 서비스 시작
docker-compose up -d

# 2. 브라우저에서 테스트
# - http://localhost:3100 접속
# - test@taskmate.com / password123 로그인
# - Tasks 페이지에서 태스크 생성 시도
# - 성공적으로 생성되는지 확인
```

### 2. API 직접 테스트
```bash
# 로그인하여 세션 토큰 획득
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{"email":"test@taskmate.com","password":"password123"}'

# 세션 토큰 확인 (cookies.txt 파일에서)
cat cookies.txt | grep session_token

# Task 생성 테스트 (Frontend Service 경유)
curl -X POST http://localhost:3100/tasks \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{"task":{"title":"테스트","description":"설명","status":"pending"}}'
```

### 3. RSpec 테스트 업데이트
**파일**: `services/frontend-service/spec/requests/tasks_spec.rb`

현재 테스트는 이미 올바르게 모킹되어 있지만, 실제 구현이 일치하지 않음.
테스트가 통과하는 것과 실제 동작이 다른 이유를 확인 필요.

## 📝 체크리스트

### 수정 필요한 파일들
- [ ] `services/frontend-service/app/controllers/tasks_controller.rb`
  - [ ] create action에 session_token 전달
  - [ ] update action에 session_token 전달
  - [ ] destroy action에 session_token 전달
  - [ ] show action 확인 (필요시)
  
- [ ] `services/frontend-service/app/services/task_service_client.rb`
  - [ ] create_task 메서드 확인
  - [ ] update_task 메서드 확인
  - [ ] delete_task 메서드 확인

### 테스트 항목
- [ ] 로그인 후 세션 토큰 정상 저장 확인
- [ ] Tasks 목록 조회 정상 작동
- [ ] Task 생성 정상 작동
- [ ] Task 수정 정상 작동
- [ ] Task 삭제 정상 작동
- [ ] 로그아웃 후 접근 차단 확인

## 🎯 예상 결과

수정 후:
- ✅ Tasks 페이지에서 17개 태스크 정상 표시
- ✅ 새로운 태스크 생성 가능
- ✅ 태스크 수정/삭제 가능
- ✅ 모든 CRUD 작업 정상 작동

## 💡 추가 개선 사항 (Optional)

1. **에러 핸들링 개선**
   - 인증 실패 시 더 명확한 에러 메시지
   - 세션 만료 시 자동 로그인 페이지 리다이렉트

2. **로깅 개선**
   - 인증 관련 로그 추가
   - 디버깅을 위한 상세 로그

3. **테스트 커버리지**
   - 인증 실패 케이스 테스트 추가
   - 세션 만료 케이스 테스트 추가

---

## 📌 Quick Fix (긴급 수정용)

가장 빠른 수정 방법:
```bash
# 1. TasksController만 수정
cd services/frontend-service
vim app/controllers/tasks_controller.rb

# 2. create, update, destroy 메서드에 다음 추가:
# session_token: session[:session_token]

# 3. 서비스 재시작
docker-compose restart frontend-service

# 4. 테스트
# 브라우저에서 http://localhost:3100 접속하여 확인
```

이 문서를 참고하여 다음 세션에서 문제를 해결하세요!