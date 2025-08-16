# 커밋 전 체크리스트

모든 커밋 전에 프로젝트 상태를 정확히 반영하고 일관성을 유지하기 위한 체크리스트입니다.

## 📋 필수 체크 항목

### 1. 코드 품질 검증
```bash
# 테스트 실행 및 통과 확인
bundle exec rspec
# 53 examples, 0 failures 확인

# 코드 스타일 검사
bundle exec rubocop
# no offenses detected 확인

# 커버리지 확인 (80% 이상 유지)
# coverage/index.html 확인
```

### 2. PROJECT_PLAN.md 업데이트

#### 현재 상태 반영
- [ ] **Phase 진행률 업데이트** (`70% 진행` 등)
- [ ] **완료된 사항** 체크박스 변경 (`[ ]` → `✅`)
- [ ] **현재 상태** 설명 업데이트
- [ ] **다음 단계** 명시 (`← **다음 단계**`)

#### 테스트 현황 업데이트
- [ ] 새로 추가된 테스트 수 반영
- [ ] 전체 테스트 수 업데이트 (예: `53개 모두 통과`)
- [ ] 코드 커버리지 퍼센트 업데이트 (예: `91.75%`)
- [ ] 새로운 기능 테스트 범위 명시

#### 기능 구현 상태 반영
- [ ] 새로 구현된 API 엔드포인트 추가
- [ ] 모델/컨트롤러 구현 완료 표시
- [ ] 보안 기능 구현 내용 반영
- [ ] 개발 도구/스크립트 추가 사항 명시

### 3. 문서 일관성 확인

#### API 엔드포인트 일치
- [ ] PROJECT_PLAN.md의 API 목록
- [ ] `config/routes.rb`의 실제 라우팅
- [ ] 컨트롤러 메서드 구현
- [ ] 테스트 케이스의 엔드포인트

#### 버전 정보 확인
- [ ] Ruby 버전 (3.4.3)
- [ ] Rails 버전 (8.0.2.1)
- [ ] 서비스 포트 번호 (User: 3000, Task: 3001, Analytics: 3002, File: 3003)
- [ ] 데이터베이스 이름 일치

### 4. Git 커밋 메시지 규칙

#### 커밋 타입 선택
- `feat`: 새로운 기능 추가
- `fix`: 버그 수정
- `docs`: 문서 변경만
- `refactor`: 코드 리팩토링
- `test`: 테스트 추가/수정
- `chore`: 빌드/설정 변경

#### 커밋 메시지 형식
```
<type>(<scope>): <subject>

<body>

Co-Authored-By: Claude <noreply@anthropic.com>
```

#### 예시
```bash
feat(user-service): AuthController TDD 구현 완료

TDD 방식으로 인증 API 컨트롤러 구현
- POST /api/v1/auth/register - 회원가입 기능
- POST /api/v1/auth/login - 로그인 기능  
- POST /api/v1/auth/logout - 로그아웃 기능
- GET /api/v1/auth/verify - 세션 검증 기능

주요 구현 사항:
- ApplicationController에 ActionController::Cookies 포함
- 세션 기반 인증 시스템 (HttpOnly 쿠키)
- 에러 응답 표준화 및 적절한 HTTP 상태 코드
- RSpec 테스트 26개 모두 통과 (91.75% 코드 커버리지)

🧪 테스트 결과: 53개 테스트 모두 통과

Co-Authored-By: Claude <noreply@anthropic.com>
```

## 🔄 자동화 체크리스트

### 커밋 전 자동 실행 스크립트
```bash
#!/bin/bash
# pre_commit_check.sh

echo "🔍 커밋 전 검증 시작..."

# 1. 테스트 실행
echo "1️⃣ 테스트 실행 중..."
bundle exec rspec
if [ $? -ne 0 ]; then
    echo "❌ 테스트 실패! 커밋을 중단합니다."
    exit 1
fi

# 2. 코드 스타일 검사
echo "2️⃣ Rubocop 검사 중..."
bundle exec rubocop
if [ $? -ne 0 ]; then
    echo "❌ 코드 스타일 검사 실패! 커밋을 중단합니다."
    exit 1
fi

# 3. PROJECT_PLAN.md 업데이트 확인
echo "3️⃣ PROJECT_PLAN.md 체크..."
if git diff --cached --name-only | grep -q "PROJECT_PLAN.md"; then
    echo "✅ PROJECT_PLAN.md 업데이트 확인됨"
else
    echo "⚠️ PROJECT_PLAN.md가 업데이트되지 않았습니다."
    echo "📝 docs/PROJECT_PLAN.md를 확인하고 업데이트하세요."
    # exit 1  # 필요시 주석 해제하여 강제 체크
fi

echo "✅ 모든 검증 통과! 커밋을 진행하세요."
```

## 📊 Progress Tracking

### Phase 2 진행 상황 체크
- [ ] User Service 프로젝트 구조 ✅
- [ ] User 모델 TDD ✅  
- [ ] Session 모델 TDD ✅
- [ ] AuthController TDD ✅
- [ ] UsersController 구현 (프로필 관리)
- [ ] Task Service 구현
- [ ] 서비스 간 통신 구현
- [ ] 통합 테스트

### 테스트 커버리지 목표
- [x] User 모델: 100% 커버리지
- [x] Session 모델: 100% 커버리지  
- [x] AuthController: 100% 커버리지
- [ ] UsersController: 80%+ 목표
- [ ] 전체 User Service: 90%+ 목표

### 문서화 상태
- [x] TDD 가이드
- [x] API 명세서
- [x] 개발 가이드
- [x] 모노레포 가이드
- [ ] 배포 가이드
- [ ] 운영 가이드

## 🚀 다음 단계 준비

### Task Service 준비 사항
- [ ] 프로젝트 구조 생성
- [ ] Task 모델 설계
- [ ] User Service 연동 계획
- [ ] API 엔드포인트 설계

### 문서 업데이트 예정
- [ ] API 명세서에 새 엔드포인트 추가
- [ ] 아키텍처 다이어그램 업데이트
- [ ] 서비스 간 통신 다이어그램 작성

---

**💡 팁**: 이 체크리스트를 커밋 전마다 확인하여 프로젝트의 일관성과 품질을 유지하세요!