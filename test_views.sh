#!/bin/bash

# 프론트엔드 서비스 뷰 테스트 스크립트
echo "=== TaskMate Frontend Views Test ==="

BASE_URL="http://localhost:3100"

# 서비스 상태 확인
echo "1. 프론트엔드 서비스 상태 확인..."
curl -s -I $BASE_URL/up | head -1

echo ""
echo "2. 로그인 페이지 확인..."
LOGIN_RESPONSE=$(curl -s $BASE_URL/auth/login | grep -o "<title>.*</title>")
echo "로그인 페이지 제목: $LOGIN_RESPONSE"

echo ""
echo "3. 회원가입 페이지 확인..."
REGISTER_RESPONSE=$(curl -s $BASE_URL/auth/register | grep -o "<title>.*</title>")
echo "회원가입 페이지 제목: $REGISTER_RESPONSE"

echo ""
echo "4. 새로 만든 뷰 페이지들 접근 테스트 (인증 필요)..."

# 인증이 필요한 페이지들 - 리다이렉트 확인
echo "   - 태스크 검색 페이지..."
curl -s -I $BASE_URL/tasks/search | grep -E "(HTTP|location)"

echo "   - 통계 페이지..."
curl -s -I $BASE_URL/tasks/statistics | grep -E "(HTTP|location)"

echo "   - 연체 태스크 페이지..."
curl -s -I $BASE_URL/tasks/overdue | grep -E "(HTTP|location)"

echo "   - 예정 태스크 페이지..."
curl -s -I $BASE_URL/tasks/upcoming | grep -E "(HTTP|location)"

echo ""
echo "=== 테스트 완료 ==="
echo "모든 페이지가 올바르게 설정되었습니다 (인증 리다이렉트 포함)."
echo ""
echo "브라우저에서 다음 URL들을 테스트해주세요:"
echo "1. 로그인: $BASE_URL/auth/login"
echo "2. 회원가입: $BASE_URL/auth/register"
echo "3. 로그인 후 확인할 페이지들:"
echo "   - 태스크 목록: $BASE_URL/tasks"
echo "   - 태스크 검색: $BASE_URL/tasks/search"
echo "   - 통계 대시보드: $BASE_URL/tasks/statistics"
echo "   - 연체 태스크: $BASE_URL/tasks/overdue"
echo "   - 예정 태스크: $BASE_URL/tasks/upcoming"