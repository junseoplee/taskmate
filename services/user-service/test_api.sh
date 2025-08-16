#!/bin/bash

# User Service API 테스트 스크립트
# 사용법: ./test_api.sh

set -e

echo "🚀 User Service API 테스트 시작"
echo "=================================="

BASE_URL="http://localhost:3000/api/v1"
COOKIE_JAR="./cookies.txt"

# 쿠키 파일 초기화
rm -f $COOKIE_JAR

echo ""
echo "1️⃣ 헬스체크 테스트"
echo "------------------"
response=$(curl -s -w "%{http_code}" http://localhost:3000/up)
echo "응답: $response"

echo ""
echo "2️⃣ 회원가입 테스트"
echo "------------------"
register_response=$(curl -s -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -c $COOKIE_JAR \
  -d '{
    "name": "테스트 사용자",
    "email": "test@example.com", 
    "password": "password123",
    "password_confirmation": "password123"
  }' \
  $BASE_URL/auth/register)

echo "회원가입 응답: $register_response"

echo ""
echo "3️⃣ 로그인 테스트"
echo "---------------"
login_response=$(curl -s -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -c $COOKIE_JAR \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }' \
  $BASE_URL/auth/login)

echo "로그인 응답: $login_response"

echo ""
echo "4️⃣ 세션 검증 테스트"
echo "------------------"
verify_response=$(curl -s -w "%{http_code}" \
  -X GET \
  -H "Content-Type: application/json" \
  -b $COOKIE_JAR \
  $BASE_URL/auth/verify)

echo "세션 검증 응답: $verify_response"

echo ""
echo "5️⃣ 로그아웃 테스트"
echo "----------------"
logout_response=$(curl -s -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -b $COOKIE_JAR \
  $BASE_URL/auth/logout)

echo "로그아웃 응답: $logout_response"

echo ""
echo "6️⃣ 로그아웃 후 세션 검증 테스트 (실패해야 함)"
echo "--------------------------------------"
verify_after_logout=$(curl -s -w "%{http_code}" \
  -X GET \
  -H "Content-Type: application/json" \
  -b $COOKIE_JAR \
  $BASE_URL/auth/verify)

echo "로그아웃 후 검증 응답: $verify_after_logout"

# 정리
rm -f $COOKIE_JAR

echo ""
echo "✅ API 테스트 완료!"
echo "===================="
echo ""
echo "📋 테스트 결과 해석:"
echo "- 200: 성공"
echo "- 201: 생성 성공 (회원가입)"
echo "- 401: 인증 실패 (로그아웃 후 검증에서 예상됨)"
echo "- 422: 유효성 검사 실패"
echo ""
echo "🔧 서버 실행 명령어:"
echo "rails server -p 3000"
echo ""
echo "🧪 개별 테스트 명령어 예시:"
echo "curl -X POST http://localhost:3000/api/v1/auth/register \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"name\":\"홍길동\",\"email\":\"hong@example.com\",\"password\":\"password123\",\"password_confirmation\":\"password123\"}'"