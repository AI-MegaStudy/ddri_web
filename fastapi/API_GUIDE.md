# DDRI FastAPI 가이드

작성일: 2026-03-20  
목적: 현재 `ddri_web` 기준 FastAPI 백엔드 구조와 실행 방법을 정리한다.

## 1. 현재 서버 역할

FastAPI는 현재 아래 역할을 맡는다.

- 사용자 조회 API 제공
- 관리자 조회 API 제공
- 스테이션 기본 정보 API 제공
- 날씨 API 제공
- 향후 외부 실시간 재고 API와 예측 모델을 연결하는 런타임 서버 역할

현재 서비스는 조회형 웹 기준이다.

- 로그인 없음
- 사용자 저장 기능 없음
- 외부 API + 로컬 마스터 + 서버 추론 구조
- DB는 필수 계층이 아니며, 필요 시 `prediction_logs`만 저장
- 현 단계에서는 마스터 데이터 API 자동 갱신과 DB 저장을 선행 범위로 두지 않음

## 2. 프로젝트 구조

```text
fastapi/
├── app/
│   ├── api/
│   │   ├── ddri_user.py
│   │   ├── ddri_admin.py
│   │   ├── ddri_stations.py
│   │   └── weather.py
│   ├── database/
│   │   ├── connection.py
│   │   └── connection_local.py
│   ├── utils/
│   │   ├── weather_service.py
│   │   └── weather_mapping.py
│   └── main.py
├── mysql/
│   └── init_schema.sql
└── API_GUIDE.md
```

## 3. 현재 등록된 라우터

`app/main.py` 기준:

- `GET /`
- `GET /health`
- `GET /v1/user/stations/nearby`
- `GET /v1/admin/stations/risk`
- `GET /v1/stations`
- `GET /v1/weather/direct`
- `GET /v1/weather/direct/single`

## 4. 현재 구현 상태

### 구현 완료

- 사용자 조회 목업 API
- 관리자 조회 목업 API
- 스테이션 기본 정보 목업 API
- Open-Meteo 기반 날씨 API
- Swagger / ReDoc 노출
- CORS 개발 설정

### 아직 미완료

- 외부 실시간 재고 API 연동
- 로컬 마스터 로딩 구조
- 예측 모델 `joblib` 런타임 연결
- 예외/폴백 처리 고도화
- 필요 시 `prediction_logs` 저장

## 5. 설치 및 실행

### 1. 가상 환경

```bash
cd fastapi
python -m venv venv
source venv/bin/activate
```

### 2. 의존성 설치

```bash
pip install -r requirements.txt
```

### 3. 환경변수

`fastapi/.env` 예시:

```env
DDRI_SERVICE_MODE=beta
DB_HOST=your_host
DB_USER=your_user
DB_PASSWORD=your_password
DB_NAME=ddri_db
DB_PORT=13306
```

설명:
- `DDRI_SERVICE_MODE=beta`: 사용자/관리자 화면에 베타 고정 6개와 `베타` 표기 노출
- `DDRI_SERVICE_MODE=live`: 베타 제한과 `베타` 표기를 끄고 운영 모드 응답 경로 사용
- 현재 DB는 필수는 아니다
- DB를 안 쓰는 동안에도 `.env`는 남겨둘 수 있다
- 추후 `prediction_logs` 저장 시 사용 가능

### 4. 서버 실행

```bash
cd fastapi
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 5. 문서 확인

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## 6. 데이터 계층 원칙

### 현재 기준

- 실시간 재고: 외부 API 기준
- 날씨: Open-Meteo 기준
- 스테이션 마스터: 로컬 데이터 또는 별도 로딩 구조 기준
- 예측 모델: 서버 로컬 파일 로드 예정
- 마스터 데이터 갱신 자동화와 DB 적재는 후순위 검토 항목
- 실시간 재고는 서울시 원천 데이터이므로 서비스 DB에 누적 저장하지 않음
- 미래 시점 재고도 예측 결과와 현재 재고의 계산값으로 다루며 기본 적재 대상이 아님

### DB 사용

현재는 필수가 아니다.

`mysql/init_schema.sql`은 최소 스키마만 포함한다.

- `prediction_logs`

즉 예전처럼 `stations`, `station_risk_snapshots`, `realtime_station_stock`를 전부 DB에 넣는 구조가 아니라, 필요 시 예측 로그만 저장하는 방향이다.
실시간 재고는 외부 API 기준값을 조회 시점에 사용하고, 서비스 내부 누적 저장은 기본 범위에서 제외한다.

현재 판단으로는 마스터 데이터 저장을 뒤로 미뤄도 최소 스키마에는 직접 영향이 없다.
검토 포인트는 스키마 변경이 아니라, 실제 운영 전환 시 `live` 모드가 어떤 마스터 원본을 읽을지다.

## 7. 날씨 API 역할

날씨는 현재 두 가지 목적에 사용한다.

1. 모델 입력 피처
2. 화면 표시 정보

화면에서는 다음 두 층으로 쓴다.

- 주간 일별 날씨
- 선택 날짜/시간 기준 상세 날씨

즉 날씨 API는 더 이상 ML 입력 전용이 아니다.

## 8. 개발 시 참고

- 기준 설계 문서:
  - [01_screen_design_and_scope.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/01_screen_design_and_scope.md)
  - [02_system_design.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/02_system_design.md)
  - [03_api_and_runtime_contract.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/03_api_and_runtime_contract.md)
- API 명세:
  - [API_SPEC.md](/Users/cheng80/Desktop/ddri_web/docs/api/API_SPEC.md)
  - [openapi.yaml](/Users/cheng80/Desktop/ddri_web/docs/api/openapi.yaml)

## 9. 다음 작업

1. 외부 실시간 재고 API 연동
2. 날씨 응답을 화면 구조와 맞게 정리
3. 로컬 마스터 JSON 로더 추가
4. 예측 모델 런타임 연결
5. 필요 시 `prediction_logs` 저장 연결
