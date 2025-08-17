#!/bin/bash

# TaskMate Docker 개발 환경 설정 스크립트

set -e

echo "🚀 TaskMate Docker 개발 환경 설정을 시작합니다..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수 정의
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Docker와 Docker Compose 설치 확인
check_docker() {
    print_status "Docker 설치 확인 중..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker가 설치되지 않았습니다. https://docs.docker.com/get-docker/ 에서 설치하세요."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose가 설치되지 않았습니다."
        exit 1
    fi
    
    print_success "Docker와 Docker Compose가 설치되어 있습니다."
}

# 기존 컨테이너 정리
cleanup_containers() {
    print_status "기존 컨테이너 정리 중..."
    docker-compose down --remove-orphans || true
    print_success "기존 컨테이너 정리 완료"
}

# Docker 이미지 빌드
build_images() {
    print_status "Docker 이미지 빌드 중..."
    
    # User Service 빌드
    print_status "User Service 이미지 빌드 중..."
    cd services/user-service
    docker build -f ../../docker/development/Dockerfile.rails -t taskmate/user-service:dev .
    cd ../..
    
    # Task Service 빌드
    print_status "Task Service 이미지 빌드 중..."
    cd services/task-service
    docker build -f ../../docker/development/Dockerfile.rails -t taskmate/task-service:dev .
    cd ../..
    
    print_success "모든 이미지 빌드 완료"
}

# 서비스 시작
start_services() {
    print_status "Docker Compose로 서비스 시작 중..."
    
    # 데이터베이스 서비스만 먼저 시작
    print_status "데이터베이스 서비스 시작 중..."
    docker-compose up -d postgres redis
    
    # 데이터베이스가 준비될 때까지 대기
    print_status "PostgreSQL 준비 대기 중..."
    until docker-compose exec -T postgres pg_isready -U taskmate; do
        echo "   PostgreSQL 대기 중..."
        sleep 2
    done
    
    print_status "Redis 준비 대기 중..."
    until docker-compose exec -T redis redis-cli ping | grep PONG; do
        echo "   Redis 대기 중..."
        sleep 1
    done
    
    # 애플리케이션 서비스 시작
    print_status "애플리케이션 서비스 시작 중..."
    docker-compose up -d user-service task-service
    
    print_success "모든 서비스가 시작되었습니다!"
}

# 서비스 상태 확인
check_services() {
    print_status "서비스 상태 확인 중..."
    
    echo ""
    print_status "컨테이너 상태:"
    docker-compose ps
    
    echo ""
    print_status "서비스 헬스 체크:"
    
    # User Service 헬스 체크
    sleep 10
    if curl -s http://localhost:3000/up > /dev/null; then
        print_success "User Service (포트 3000) 정상 작동"
    else
        print_warning "User Service 응답 없음 - 초기화 중일 수 있습니다"
    fi
    
    # Task Service 헬스 체크
    if curl -s http://localhost:3001/up > /dev/null; then
        print_success "Task Service (포트 3001) 정상 작동"
    else
        print_warning "Task Service 응답 없음 - 초기화 중일 수 있습니다"
    fi
}

# 로그 확인 옵션
show_logs() {
    if [[ "$1" == "--logs" ]]; then
        print_status "서비스 로그 확인:"
        docker-compose logs --tail=50 -f
    fi
}

# 메인 실행
main() {
    echo "🏗️  TaskMate 마이크로서비스 Docker 환경 설정"
    echo "================================================"
    
    check_docker
    cleanup_containers
    build_images
    start_services
    check_services
    
    echo ""
    echo "================================================"
    print_success "TaskMate Docker 환경 설정 완료!"
    echo ""
    echo "📋 서비스 접속 정보:"
    echo "   • User Service:  http://localhost:3000"
    echo "   • Task Service:  http://localhost:3001"
    echo "   • PostgreSQL:    localhost:5432"
    echo "   • Redis:         localhost:6379"
    echo ""
    echo "🔧 유용한 명령어:"
    echo "   • 로그 확인:     docker-compose logs -f"
    echo "   • 서비스 중지:   docker-compose down"
    echo "   • 서비스 재시작: docker-compose restart"
    echo "   • 컨테이너 상태: docker-compose ps"
    echo ""
    
    if [[ "$1" == "--logs" ]]; then
        show_logs "--logs"
    else
        echo "💡 실시간 로그를 보려면: $0 --logs"
    fi
}

# 스크립트 실행
main "$@"