# Backend Secrets 설정 가이드 🔐

## 개요

백엔드 애플리케이션이 사용하는 민감한 정보(데이터베이스 URL, Redis 비밀번호, JWT Secret Key)를 Kubernetes Secret으로 관리합니다.

## 필요한 시크릿 정보

### 1. DATABASE_URL (필수)
PostgreSQL 데이터베이스 연결 문자열

**형식:**
```
postgresql://[username]:[password]@[host]:[port]/[database]
```

**예시:**
```
postgresql://runna_user:mypassword123@runna-db.abc123.ap-northeast-2.rds.amazonaws.com:5432/runna_db
```

### 2. REDIS_PASSWORD (선택사항)
Redis 인스턴스 비밀번호 (Redis에 인증이 설정된 경우)

**예시:**
```
myredispassword123
```

### 3. SECRET_KEY (필수)
JWT 토큰 서명에 사용되는 비밀 키 (최소 32자 권장)

**예시:**
```
your-super-secret-key-here-at-least-32-characters-long
```

**생성 방법:**
```bash
# Linux/Mac
openssl rand -hex 32

# Python
python -c "import secrets; print(secrets.token_hex(32))"
```

## 설정 방법

### 방법 1: 자동 스크립트 사용 (권장)

#### Linux/Mac:
```bash
# 실행 권한 부여
chmod +x scripts/create-backend-secrets.sh

# 스크립트 실행
./scripts/create-backend-secrets.sh
```

#### Windows (PowerShell):
```powershell
# 스크립트 실행
.\scripts\create-backend-secrets.ps1
```

스크립트가 대화형으로 시크릿 정보를 입력받아 자동으로 Kubernetes Secret을 생성합니다.

### 방법 2: kubectl 명령어 직접 실행

#### Redis 비밀번호가 있는 경우:
```bash
kubectl create secret generic backend-secrets \
  --from-literal=database-url='postgresql://user:pass@host:5432/db' \
  --from-literal=redis-password='your-redis-password' \
  --from-literal=secret-key='your-secret-key-min-32-chars' \
  -n default
```

#### Redis 비밀번호가 없는 경우:
```bash
kubectl create secret generic backend-secrets \
  --from-literal=database-url='postgresql://user:pass@host:5432/db' \
  --from-literal=secret-key='your-secret-key-min-32-chars' \
  -n default
```

## Secret 확인

### Secret 존재 확인:
```bash
kubectl get secret backend-secrets
```

### Secret 상세 정보 확인:
```bash
kubectl describe secret backend-secrets
```

### Secret 값 확인 (base64 디코딩):
```bash
# DATABASE_URL 확인
kubectl get secret backend-secrets -o jsonpath='{.data.database-url}' | base64 --decode

# SECRET_KEY 확인
kubectl get secret backend-secrets -o jsonpath='{.data.secret-key}' | base64 --decode

# REDIS_PASSWORD 확인
kubectl get secret backend-secrets -o jsonpath='{.data.redis-password}' | base64 --decode
```

## Secret 업데이트

기존 Secret을 업데이트하려면:

```bash
# Secret 삭제
kubectl delete secret backend-secrets

# 새로운 Secret 생성
./scripts/create-backend-secrets.sh
```

또는 직접 수정:
```bash
kubectl edit secret backend-secrets
```

## Secret 삭제

```bash
kubectl delete secret backend-secrets
```

## 환경별 Secret 관리

현재는 단일 환경(production)만 사용하지만, 향후 dev/staging 환경을 분리할 경우:

```bash
# Development 환경
kubectl create secret generic backend-secrets \
  --from-literal=database-url='...' \
  --from-literal=secret-key='...' \
  -n development

# Staging 환경
kubectl create secret generic backend-secrets \
  --from-literal=database-url='...' \
  --from-literal=secret-key='...' \
  -n staging

# Production 환경
kubectl create secret generic backend-secrets \
  --from-literal=database-url='...' \
  --from-literal=secret-key='...' \
  -n production
```

## 보안 주의사항

⚠️ **중요:**
- Secret 값은 절대 Git에 커밋하지 마세요
- Secret 값은 안전한 비밀번호 관리자에 저장하세요
- 프로덕션 환경의 SECRET_KEY는 충분히 길고 복잡하게 생성하세요 (최소 32자)
- 정기적으로 비밀번호를 변경하세요
- Secret 값을 로그에 출력하지 마세요

## Helm Values 연동

생성된 Secret은 Helm values 파일에서 다음과 같이 참조됩니다:

```yaml
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: backend-secrets
        key: database-url
  
  - name: REDIS_PASSWORD
    valueFrom:
      secretKeyRef:
        name: backend-secrets
        key: redis-password
        optional: true
  
  - name: SECRET_KEY
    valueFrom:
      secretKeyRef:
        name: backend-secrets
        key: secret-key
```

## 트러블슈팅

### Secret이 생성되지 않는 경우:
```bash
# kubectl 연결 확인
kubectl cluster-info

# 네임스페이스 확인
kubectl get namespaces

# 권한 확인
kubectl auth can-i create secrets
```

### Pod가 Secret을 찾지 못하는 경우:
```bash
# Secret이 올바른 네임스페이스에 있는지 확인
kubectl get secret backend-secrets -n default

# Pod 로그 확인
kubectl logs <pod-name>

# Pod 이벤트 확인
kubectl describe pod <pod-name>
```

## 참고 자료

- [Kubernetes Secrets 공식 문서](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Helm Values 파일](../helm/values/values-backend-dev.yaml)
- [Backend 환경변수 설정](../backend-repo/.env.example)

---

**작성일:** 2024-12-06  
**작성자:** 서영  
**용도:** 백엔드 시크릿 설정 가이드
