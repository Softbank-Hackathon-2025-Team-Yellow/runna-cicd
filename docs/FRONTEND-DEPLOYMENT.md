# Frontend 배포 가이드

## 📋 개요

Runna Frontend는 **AWS Amplify**를 사용하여 배포됩니다.
K8s 클러스터가 아닌 Amplify의 정적 호스팅을 사용합니다.

## 🏗️ 아키텍처

```
GitHub (runna-client)
  ↓
AWS Amplify (자동 빌드)
  ↓
S3 + CloudFront (정적 호스팅)
  ↓
사용자 접근
```

## 🚀 배포 방법

### 1. AWS Amplify Console 설정

#### 1.1 새 앱 생성
1. [AWS Amplify Console](https://console.aws.amazon.com/amplify/) 접속
2. "New app" → "Host web app" 클릭
3. "GitHub" 선택
4. 저장소 권한 승인

#### 1.2 저장소 연결
1. `runna-client` 저장소 선택
2. 배포할 브랜치 선택:
   - **main**: Production
   - **develop**: Staging (선택사항)

#### 1.3 빌드 설정 확인
Amplify가 자동으로 `amplify.yml` 파일을 감지합니다:

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm ci
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: dist
    files:
      - '**/*'
```

### 2. 환경 변수 설정

Amplify Console → "Environment variables" 섹션에서 설정:

#### Development/Staging
```
VITE_USE_MOCK_DATA=false
VITE_API_URL=https://api-dev.runna.dev
```

#### Production
```
VITE_USE_MOCK_DATA=false
VITE_API_URL=https://api.runna.dev
```

### 3. 배포 시작

1. "Save and deploy" 클릭
2. 자동으로 빌드 및 배포 시작
3. 약 3-5분 소요

### 4. 배포 확인

배포 완료 후:
- Amplify가 제공하는 URL 확인 (예: `https://main.xxxxx.amplifyapp.com`)
- 브라우저에서 접속하여 동작 확인

## 🔄 자동 배포

### GitHub 연동
- `main` 브랜치에 push하면 자동으로 재배포
- PR 생성 시 프리뷰 환경 자동 생성 (선택사항)

### 배포 플로우
```
코드 푸시 (GitHub)
  ↓
Amplify 자동 감지
  ↓
npm ci (의존성 설치)
  ↓
npm run build (Vite 빌드)
  ↓
dist/ 폴더 → S3 업로드
  ↓
CloudFront 캐시 무효화
  ↓
배포 완료
```

## 🌐 커스텀 도메인 설정

### 1. 도메인 추가
1. Amplify Console → "Domain management"
2. "Add domain" 클릭
3. 도메인 입력 (예: `runna.dev`)

### 2. DNS 설정
Amplify가 제공하는 CNAME 레코드를 DNS에 추가:

```
Type: CNAME
Name: www
Value: xxxxx.cloudfront.net
```

### 3. SSL 인증서
- Amplify가 자동으로 AWS Certificate Manager 인증서 발급
- HTTPS 자동 활성화

### 4. 서브도메인 설정 (선택사항)
```
app.runna.dev → Production
staging.runna.dev → Staging
```

## 🔧 로컬 개발

### 환경 설정
```bash
# .env 파일 생성
cp .env.example .env

# 개발 서버 실행
npm run dev
```

### Mock 데이터 사용
```env
# .env
VITE_USE_MOCK_DATA=true
VITE_API_URL=http://localhost:8000
```

### 실제 Backend 연결
```env
# .env
VITE_USE_MOCK_DATA=false
VITE_API_URL=http://localhost:8000
```

## 📊 모니터링

### Amplify Console
- **Build logs**: 빌드 과정 확인
- **Deployment history**: 배포 이력
- **Metrics**: 트래픽, 에러율 등

### CloudWatch
- **Access logs**: 사용자 접근 로그
- **Error logs**: 에러 발생 로그

## 🐛 트러블슈팅

### 빌드 실패

#### 문제: `dist` 폴더가 비어있음
```bash
# 로컬에서 빌드 테스트
npm run build
ls -la dist/  # index.html이 있는지 확인
```

#### 문제: 환경 변수 누락
- Amplify Console에서 환경 변수 설정 확인
- `.env.example` 파일 참고

#### 문제: Node 버전 불일치
- Amplify Console → Build settings → Build image settings
- Node.js 18.x 선택

### 라우팅 문제 (404 에러)

#### 원인
SPA 라우팅 시 새로고침하면 404 발생

#### 해결
`public/_redirects` 파일 확인:
```
/*    /index.html   200
```

### API 연결 실패

#### 문제: CORS 에러
Backend에서 CORS 설정 확인:
```python
# backend/app/main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://your-amplify-url.amplifyapp.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

#### 문제: API URL 잘못됨
Amplify Console에서 `VITE_API_URL` 확인

## ✅ 배포 체크리스트

### 배포 전
- [ ] `npm run build` 로컬에서 성공
- [ ] `dist/index.html` 파일 존재
- [ ] `.env.example` 파일 존재
- [ ] `amplify.yml` 파일 존재
- [ ] `public/_redirects` 파일 존재

### Amplify 설정
- [ ] GitHub 저장소 연결
- [ ] 브랜치 선택 (main)
- [ ] 환경 변수 설정
- [ ] 빌드 설정 확인

### 배포 후
- [ ] 메인 페이지 로딩 확인
- [ ] 라우팅 동작 확인 (새로고침 시 404 없음)
- [ ] 환경 변수 적용 확인
- [ ] API 연결 확인
- [ ] 커스텀 도메인 동작 확인 (설정한 경우)

## 🔗 참고 링크

- [AWS Amplify 문서](https://docs.aws.amazon.com/amplify/)
- [Vite 배포 가이드](https://vitejs.dev/guide/static-deploy.html)
- [프론트엔드 저장소](https://github.com/Softbank-Hackathon-2025-Team-Yellow/runna-client)

## 💡 팁

### 빠른 배포 테스트
```bash
# 로컬에서 프로덕션 빌드 테스트
npm run build
npm run preview
```

### 환경별 설정
```bash
# Staging 브랜치 생성
git checkout -b staging
git push origin staging

# Amplify에서 staging 브랜치 추가
# → 자동으로 staging 환경 생성
```

### 비용 최적화
- CloudFront 캐시 설정 최적화
- 불필요한 브랜치 배포 비활성화
- 프리뷰 환경 자동 삭제 설정

---

**작성일:** 2024-12-04
**작성자:** 서영
