#!/bin/bash

# TaskMate Minikube Kubernetes 환경 설정 스크립트

set -e

echo "☸️  TaskMate Minikube Kubernetes 환경 설정을 시작합니다..."

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

# Minikube와 kubectl 설치 확인
check_tools() {
    print_status "필수 도구 설치 확인 중..."
    
    if ! command -v minikube &> /dev/null; then
        print_error "Minikube가 설치되지 않았습니다."
        echo "설치 방법: https://minikube.sigs.k8s.io/docs/start/"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl이 설치되지 않았습니다."
        echo "설치 방법: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker가 설치되지 않았습니다."
        exit 1
    fi
    
    print_success "모든 필수 도구가 설치되어 있습니다."
}

# Minikube 시작
start_minikube() {
    print_status "Minikube 클러스터 시작 중..."
    
    # Minikube가 이미 실행 중인지 확인
    if minikube status | grep -q "Running"; then
        print_warning "Minikube가 이미 실행 중입니다."
    else
        print_status "Minikube 시작 중... (최초 실행 시 시간이 걸릴 수 있습니다)"
        minikube start \
            --driver=docker \
            --memory=4096 \
            --cpus=2 \
            --disk-size=20g \
            --kubernetes-version=v1.28.3
    fi
    
    # Docker 환경 설정
    print_status "Docker 환경을 Minikube로 설정 중..."
    eval $(minikube -p minikube docker-env)
    
    print_success "Minikube 클러스터가 실행 중입니다."
}

# Docker 이미지 빌드 (Minikube 환경에서)
build_images_for_minikube() {
    print_status "Minikube 환경에서 Docker 이미지 빌드 중..."
    
    # Minikube Docker 환경 설정
    eval $(minikube -p minikube docker-env)
    
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
    
    print_success "모든 이미지가 Minikube에 빌드되었습니다."
}

# Kubernetes 네임스페이스 및 리소스 배포
deploy_to_kubernetes() {
    print_status "Kubernetes 리소스 배포 중..."
    
    # 네임스페이스 생성
    print_status "네임스페이스 생성 중..."
    kubectl apply -f k8s/development/namespace.yaml
    
    # 데이터베이스 배포
    print_status "데이터베이스 서비스 배포 중..."
    kubectl apply -f k8s/development/database/
    
    # 데이터베이스 준비 대기
    print_status "PostgreSQL 준비 대기 중..."
    kubectl wait --for=condition=ready pod -l app=postgres -n taskmate-dev --timeout=300s
    
    print_status "Redis 준비 대기 중..."
    kubectl wait --for=condition=ready pod -l app=redis -n taskmate-dev --timeout=300s
    
    # 애플리케이션 서비스 배포
    print_status "애플리케이션 서비스 배포 중..."
    kubectl apply -f k8s/development/services/
    
    # 애플리케이션 준비 대기
    print_status "User Service 준비 대기 중..."
    kubectl wait --for=condition=ready pod -l app=user-service -n taskmate-dev --timeout=300s
    
    print_status "Task Service 준비 대기 중..."
    kubectl wait --for=condition=ready pod -l app=task-service -n taskmate-dev --timeout=300s
    
    print_success "모든 서비스가 배포되었습니다!"
}

# 서비스 상태 확인
check_services() {
    print_status "Kubernetes 서비스 상태 확인 중..."
    
    echo ""
    print_status "Pod 상태:"
    kubectl get pods -n taskmate-dev
    
    echo ""
    print_status "Service 상태:"
    kubectl get services -n taskmate-dev
    
    echo ""
    print_status "외부 접속 URL:"
    USER_SERVICE_URL=$(minikube service user-service-nodeport -n taskmate-dev --url)
    TASK_SERVICE_URL=$(minikube service task-service-nodeport -n taskmate-dev --url)
    
    echo "   • User Service:  $USER_SERVICE_URL"
    echo "   • Task Service:  $TASK_SERVICE_URL"
}

# 통합 테스트 실행
run_integration_test() {
    if [[ "$1" == "--test" ]]; then
        print_status "통합 테스트 실행 중..."
        
        USER_SERVICE_URL=$(minikube service user-service-nodeport -n taskmate-dev --url)
        TASK_SERVICE_URL=$(minikube service task-service-nodeport -n taskmate-dev --url)
        
        # User Service 헬스 체크
        print_status "User Service 헬스 체크..."
        if curl -s "$USER_SERVICE_URL/up" > /dev/null; then
            print_success "User Service 정상 작동"
        else
            print_warning "User Service 응답 없음"
        fi
        
        # Task Service 헬스 체크
        print_status "Task Service 헬스 체크..."
        if curl -s "$TASK_SERVICE_URL/up" > /dev/null; then
            print_success "Task Service 정상 작동"
        else
            print_warning "Task Service 응답 없음"
        fi
    fi
}

# 리소스 정리
cleanup() {
    if [[ "$1" == "--cleanup" ]]; then
        print_status "Kubernetes 리소스 정리 중..."
        kubectl delete namespace taskmate-dev --ignore-not-found=true
        print_success "리소스 정리 완료"
        
        if [[ "$2" == "--stop" ]]; then
            print_status "Minikube 중지 중..."
            minikube stop
            print_success "Minikube 중지 완료"
        fi
    fi
}

# 도움말 표시
show_help() {
    echo "TaskMate Minikube 설정 스크립트"
    echo ""
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --test     배포 후 통합 테스트 실행"
    echo "  --cleanup  Kubernetes 리소스 정리"
    echo "  --stop     리소스 정리 후 Minikube 중지"
    echo "  --help     이 도움말 표시"
    echo ""
}

# 메인 실행
main() {
    # 도움말 체크
    if [[ "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    # 정리 옵션 체크
    if [[ "$1" == "--cleanup" ]]; then
        cleanup "--cleanup" "$2"
        exit 0
    fi
    
    echo "☸️  TaskMate 마이크로서비스 Kubernetes 환경 설정"
    echo "====================================================="
    
    check_tools
    start_minikube
    build_images_for_minikube
    deploy_to_kubernetes
    check_services
    run_integration_test "$1"
    
    echo ""
    echo "====================================================="
    print_success "TaskMate Kubernetes 환경 설정 완료!"
    echo ""
    echo "🔧 유용한 명령어:"
    echo "   • Pod 로그 확인:     kubectl logs -f <pod-name> -n taskmate-dev"
    echo "   • 서비스 상태 확인:  kubectl get all -n taskmate-dev"
    echo "   • 서비스 접속:       minikube service <service-name> -n taskmate-dev"
    echo "   • 대시보드 실행:     minikube dashboard"
    echo ""
    echo "🧹 정리 명령어:"
    echo "   • 리소스 정리:       $0 --cleanup"
    echo "   • 완전 정리:         $0 --cleanup --stop"
    echo ""
}

# 스크립트 실행
main "$@"