#!/bin/bash

# Backend Secrets 생성 스크립트
# 사용법: ./scripts/create-backend-secrets.sh

set -e

echo "=========================================="
echo "🔐 Backend Secrets 생성"
echo "=========================================="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 시크릿 값 입력 받기
echo -e "${YELLOW}📝 시크릿 정보를 입력하세요:${NC}"
echo ""

# DATABASE_URL
echo -e "${GREEN}1. DATABASE_URL${NC}"
echo "   예시: postgresql://user:password@host:5432/dbname"
read -p "   입력: " DATABASE_URL

# REDIS_PASSWORD (선택사항)
echo ""
echo -e "${GREEN}2. REDIS_PASSWORD (선택사항, 없으면 Enter)${NC}"
read -s -p "   입력: " REDIS_PASSWORD
echo ""

# SECRET_KEY
echo ""
echo -e "${GREEN}3. SECRET_KEY (JWT 토큰 서명용)${NC}"
echo "   예시: your-super-secret-key-here-min-32-chars"
read -s -p "   입력: " SECRET_KEY
echo ""

echo ""
echo "=========================================="
echo "🚀 Kubernetes Secret 생성 중..."
echo "=========================================="
echo ""

# Secret 생성 명령어 구성
if [ -z "$REDIS_PASSWORD" ]; then
  # Redis 비밀번호가 없는 경우
  kubectl create secret generic backend-secrets \
    --from-literal=database-url="$DATABASE_URL" \
    --from-literal=secret-key="$SECRET_KEY" \
    --dry-run=client -o yaml | kubectl apply -f -
else
  # Redis 비밀번호가 있는 경우
  kubectl create secret generic backend-secrets \
    --from-literal=database-url="$DATABASE_URL" \
    --from-literal=redis-password="$REDIS_PASSWORD" \
    --from-literal=secret-key="$SECRET_KEY" \
    --dry-run=client -o yaml | kubectl apply -f -
fi

echo ""
echo -e "${GREEN}✅ Secret 생성 완료!${NC}"
echo ""

# Secret 확인
echo "=========================================="
echo "📋 생성된 Secret 확인"
echo "=========================================="
kubectl get secret backend-secrets -o yaml

echo ""
echo -e "${GREEN}✅ 모든 작업 완료!${NC}"
echo ""
echo "다음 명령어로 Secret을 확인할 수 있습니다:"
echo "  kubectl describe secret backend-secrets"
echo ""
