#!/bin/bash
# pre_commit_check.sh - 커밋 전 자동 검증 스크립트

set -e

echo "🔍 User Service 커밋 전 검증 시작..."
echo "======================================"

# 현재 디렉토리 확인
if [ ! -f "Gemfile" ]; then
    echo "❌ User Service 디렉토리에서 실행해주세요."
    echo "📂 cd services/user-service"
    exit 1
fi

echo ""
echo "1️⃣ 테스트 실행 중..."
echo "-------------------"
bundle exec rspec --format progress
if [ $? -ne 0 ]; then
    echo "❌ 테스트 실패! 커밋을 중단합니다."
    echo "🔧 테스트 오류를 수정한 후 다시 시도하세요."
    exit 1
fi

echo ""
echo "2️⃣ 코드 스타일 검사 중..."
echo "------------------------"
bundle exec rubocop
if [ $? -ne 0 ]; then
    echo "❌ 코드 스타일 검사 실패!"
    echo "🔧 자동 수정을 시도합니다..."
    bundle exec rubocop -A
    if [ $? -ne 0 ]; then
        echo "❌ 자동 수정 실패! 수동으로 수정이 필요합니다."
        exit 1
    fi
    echo "✅ 코드 스타일 자동 수정 완료"
fi

echo ""
echo "3️⃣ 테스트 커버리지 확인..."
echo "------------------------"
coverage_percent=$(grep -o 'Line Coverage: [0-9]*\.[0-9]*%' coverage/index.html 2>/dev/null | grep -o '[0-9]*\.[0-9]*' || echo "0")
if [ -n "$coverage_percent" ]; then
    echo "📊 현재 커버리지: ${coverage_percent}%"
    if (( $(echo "$coverage_percent >= 80" | bc -l) )); then
        echo "✅ 커버리지 목표 달성 (80% 이상)"
    else
        echo "⚠️ 커버리지가 80% 미만입니다. (현재: ${coverage_percent}%)"
    fi
else
    echo "⚠️ 커버리지 정보를 확인할 수 없습니다."
fi

echo ""
echo "4️⃣ 테스트 결과 요약..."
echo "--------------------"
test_summary=$(bundle exec rspec --format json | jq -r '.summary_line' 2>/dev/null || echo "테스트 요약 정보 없음")
echo "📋 $test_summary"

echo ""
echo "5️⃣ PROJECT_PLAN.md 업데이트 체크..."
echo "---------------------------------"
project_plan="../../docs/PROJECT_PLAN.md"
if [ -f "$project_plan" ]; then
    if git diff --cached --name-only | grep -q "docs/PROJECT_PLAN.md"; then
        echo "✅ PROJECT_PLAN.md 업데이트 확인됨"
    else
        echo "⚠️ PROJECT_PLAN.md가 스테이징되지 않았습니다."
        echo "📝 필요시 docs/PROJECT_PLAN.md를 업데이트하고 git add 하세요."
    fi
else
    echo "⚠️ PROJECT_PLAN.md를 찾을 수 없습니다."
fi

echo ""
echo "6️⃣ 커밋 메시지 가이드..."
echo "----------------------"
echo "📝 권장 커밋 메시지 형식:"
echo ""
echo "feat(user-service): 기능 설명"
echo ""
echo "상세 설명"
echo "- 주요 변경사항 1"
echo "- 주요 변경사항 2"
echo ""
echo "🧪 테스트 결과: N개 테스트 모두 통과"
echo ""
echo "Co-Authored-By: Claude <noreply@anthropic.com>"

echo ""
echo "✅ 모든 검증 통과!"
echo "=================="
echo "🚀 이제 안전하게 커밋할 수 있습니다."
echo ""
echo "💡 다음 단계:"
echo "1. git add ."
echo "2. git commit -m '적절한 커밋 메시지'"
echo "3. 필요시 git push"