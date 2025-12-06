#!/bin/bash
# ArgoCD Applications 배포 스크립트
# Usage: bash scripts/deploy-argocd-apps.sh

echo "=== ArgoCD Applications 배포 시작 ==="
echo ""

# 1. Root App 배포
echo "1. Root Application 배포 중..."
kubectl apply -f argocd/root-app.yaml

if [ $? -eq 0 ]; then
    echo "✅ Root Application 배포 완료"
else
    echo "❌ Root Application 배포 실패"
    exit 1
fi

echo ""
echo "2. Applications 생성 대기 중 (10초)..."
sleep 10

# 2. Applications 확인
echo ""
echo "3. 생성된 Applications 확인:"
kubectl get applications -n argocd

echo ""
echo "4. Applications 상세 상태:"
kubectl get applications -n argocd -o wide

echo ""
echo "=== 배포 완료 ==="
echo ""
echo "다음 단계:"
echo "1. ArgoCD UI 확인: https://argocd.haifu.cloud/applications"
echo "2. Applications 동기화 상태 확인"
echo "3. 필요시 수동 Sync 실행"
echo ""
