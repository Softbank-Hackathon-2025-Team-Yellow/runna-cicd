# Docker Hub 백엔드 이미지 테스트 가이드

## 📦 필요한 정보

### 1. Docker 이미지 정보
```
Registry: docker.io
Repository: ytjdud79/backend
Latest Tag: 2302f648a445542
Full Image: docker.io/ytjdud79/backend:2302f648a445542
```

### 2. Repository 접근 권한

**현재 상태:**
- Repository는 **Private**입니다
- 접근하려면 권한이 필요합니다

**접근 방법:**
1. Docker Hub 계정 생성 (없으면)
2. Docker Hub username을 저에게 알려주기
3. Collaborator로 초대받기
4. 초대 수락 후 이미지 pull 가능

---

## 🚀 로컬 테스트 방법

### Step 1: Docker 로그인

```bash
# Docker Hub 로그인
docker login

# Username: [your-dockerhub-username]
# Password: [your-dockerhub-password]
```

### Step 2: 이미지 Pull

```bash
# 최신 이미지 pull
docker pull ytjdud79/backend:2302f648a445542

# 또는 latest 태그 (있으면)
docker pull ytjdud79/backend:latest
```

### Step 3: 이미지 확인

```bash
# Pull한 이미지 확인
docker images | grep backend

# 출력 예시:
# ytjdud79/backend    2302f648a445542    abc123def456    2 hours ago    500MB
```

### Step 4: 컨테이너 실행

#### Option A: 기본 실행 (환경변수 없이)

```bash
docker run -d \
  --name backend-test \
  -p 8000:8000 \
  ytjdud79/backend:2302f648a445542
```

#### Option B: 환경변수 포함 실행

```bash
docker run -d \
  --name backend-test \
  -p 8000:8000 \
  -e DATABASE_URL="postgresql://user:pass@localhost:5432/db" \
  -e REDIS_HOST="localhost" \
  -e REDIS_PORT="6379" \
  -e SECRET_KEY="your-secret-key" \
  -e ENVIRONMENT="development" \
  -e DEBUG="true" \
  ytjdud79/backend:2302f648a445542
```

#### Option C: .env 파일 사용

```bash
# .env 파일 생성
cat > .env << EOF
DATABASE_URL=postgresql://user:pass@localhost:5432/db
REDIS_HOST=localhost
REDIS_PORT=6379
SECRET_KEY=your-secret-key
ENVIRONMENT=development
DEBUG=true
EOF

# 컨테이너 실행
docker run -d \
  --name backend-test \
  -p 8000:8000 \
  --env-file .env \
  ytjdud79/backend:2302f648a445542
```

### Step 5: 테스트

```bash
# 1. 컨테이너 상태 확인
docker ps | grep backend-test

# 2. 로그 확인
docker logs backend-test

# 3. 실시간 로그 보기
docker logs -f backend-test

# 4. API 테스트
curl http://localhost:8000/health
curl http://localhost:8000/docs  # Swagger UI

# 5. 컨테이너 내부 접속
docker exec -it backend-test /bin/bash
```

### Step 6: 정리

```bash
# 컨테이너 중지
docker stop backend-test

# 컨테이너 삭제
docker rm backend-test

# 이미지 삭제 (필요시)
docker rmi ytjdud79/backend:2302f648a445542
```

---

## 🔧 필요한 환경변수

백엔드가 제대로 작동하려면 다음 환경변수들이 필요합니다:

### 필수 환경변수

```bash
# Database
DATABASE_URL=postgresql://user:password@host:5432/database

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=your-redis-password  # optional

# Security
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Environment
ENVIRONMENT=development
DEBUG=true
```

### 선택적 환경변수

```bash
# Knative (서버리스 기능용)
KNATIVE_URL=http://localhost:8080
KNATIVE_TIMEOUT=30
```

---

## 🐳 Docker Compose로 테스트 (추천)

전체 스택(Backend + PostgreSQL + Redis)을 함께 테스트하려면:

### docker-compose.yml 생성

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: runna
      POSTGRES_PASSWORD: runna123
      POSTGRES_DB: runna_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

  backend:
    image: ytjdud79/backend:2302f648a445542
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://runna:runna123@postgres:5432/runna_db
      REDIS_HOST: redis
      REDIS_PORT: 6379
      SECRET_KEY: dev-secret-key-change-in-production
      ENVIRONMENT: development
      DEBUG: "true"
    depends_on:
      - postgres
      - redis

volumes:
  postgres_data:
  redis_data:
```

### 실행

```bash
# 전체 스택 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f backend

# API 테스트
curl http://localhost:8000/health
curl http://localhost:8000/docs

# 정리
docker-compose down
docker-compose down -v  # 볼륨까지 삭제
```

---

## 📝 트러블슈팅

### 1. 이미지 Pull 실패

```bash
# 에러: unauthorized: authentication required
# 해결: Docker Hub 로그인 확인
docker login
```

### 2. 컨테이너 시작 실패

```bash
# 로그 확인
docker logs backend-test

# 일반적인 원인:
# - 환경변수 누락
# - 데이터베이스 연결 실패
# - 포트 충돌 (8000번 포트가 이미 사용 중)
```

### 3. 포트 충돌

```bash
# 다른 포트로 실행
docker run -d \
  --name backend-test \
  -p 8080:8000 \
  ytjdud79/backend:2302f648a445542

# 접속: http://localhost:8080
```

### 4. 데이터베이스 연결 실패

```bash
# PostgreSQL이 실행 중인지 확인
docker ps | grep postgres

# 또는 로컬 PostgreSQL 사용
# DATABASE_URL을 로컬 DB로 변경
```

---

## 🔐 보안 주의사항

**공유하지 말아야 할 것:**
- Docker Hub 비밀번호
- Access Token
- Production 환경변수 (SECRET_KEY, DATABASE_URL 등)

**공유해도 되는 것:**
- Repository 이름 (ytjdud79/backend)
- 이미지 태그
- 이 가이드 문서

---

## 📞 문제 발생 시

1. Docker 로그 확인: `docker logs backend-test`
2. 컨테이너 상태 확인: `docker ps -a`
3. 이미지 확인: `docker images`
4. 저에게 연락 (에러 로그 포함)

---

## 🎯 빠른 테스트 스크립트

```bash
#!/bin/bash
# quick-test.sh

echo "=== Backend 이미지 테스트 ==="

# 1. 이미지 Pull
echo "1. 이미지 Pull 중..."
docker pull ytjdud79/backend:2302f648a445542

# 2. 기존 컨테이너 정리
echo "2. 기존 컨테이너 정리..."
docker stop backend-test 2>/dev/null
docker rm backend-test 2>/dev/null

# 3. 컨테이너 실행
echo "3. 컨테이너 실행 중..."
docker run -d \
  --name backend-test \
  -p 8000:8000 \
  -e ENVIRONMENT="development" \
  -e DEBUG="true" \
  ytjdud79/backend:2302f648a445542

# 4. 대기
echo "4. 서버 시작 대기 (10초)..."
sleep 10

# 5. 테스트
echo "5. API 테스트..."
curl -s http://localhost:8000/health || echo "Health check failed"

# 6. 로그 출력
echo "6. 컨테이너 로그:"
docker logs backend-test

echo ""
echo "=== 테스트 완료 ==="
echo "Swagger UI: http://localhost:8000/docs"
echo "로그 보기: docker logs -f backend-test"
echo "정리: docker stop backend-test && docker rm backend-test"
```

실행:
```bash
chmod +x quick-test.sh
./quick-test.sh
```
