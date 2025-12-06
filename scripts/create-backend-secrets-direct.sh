#!/bin/bash

# Backend Secrets 직접 생성 스크립트
# 받은 .env 정보를 기반으로 Secret 생성

set -e

echo "=========================================="
echo "🔐 Backend Secrets 생성 (Direct)"
echo "=========================================="
echo ""

# 받은 정보
DATABASE_URL="postgresql://user:password@localhost:5432/runna_db"
SECRET_KEY="b7b482449580b9fdf430e28d39b9f3b0bbb570de441a2e3dc69697ffbb307d91"

echo "📝 다음 정보로 Secret을 생성합니다:"
echo "  - DATABASE_URL: postgresql://user:password@localhost:5432/runna_db"
echo "  - SECRET_KEY: b7b48244... (64자)"
echo "  - REDIS_PASSWORD: (없음)"
echo ""

read -p "계속하시겠습니까? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "취소되었습니다."
    exit 1
fi

echo ""
echo "🚀 Kubernetes Secret 생성 중..."
echo ""

# Secret 생성 (Redis 비밀번호 없음)
kubectl create secret generic backend-secrets \
  --from-literal=database-url="$DATABASE_URL" \
  --from-literal=secret-key="$SECRET_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "✅ Secret 생성 완료!"
echo ""

# Secret 확인
echo "=========================================="
echo "📋 생성된 Secret 확인"
echo "=========================================="
kubectl describe secret backend-secrets

echo ""
echo "✅ 모든 작업 완료!"
echo ""
