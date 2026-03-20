# DDRI FastAPI 가이드

작성일: 2026-03-20  
갱신일: 2026-03-20  
목적: 현재 `ddri_web` 기준 FastAPI 백엔드의 구조, 실행 방법, 런타임 원칙을 정리한다.

## 1. 현재 서버 역할

FastAPI는 현재 아래 역할을 맡는다.

- 사용자 페이지 `/user`용 조회 API 제공
- 관리자 페이지 `/admin`용 조회 API 제공
- 스테이션 마스터 목록 API 제공
- Open-Meteo 기반 날씨 API 제공
- 향후 외부 실시간 재고 API와 예측 모델을 연결할 런타임 진입점 제공

현재 서비스 특성:

- 로그인 없음
- 조회 전용
- 사용자 저장 기능 없음
- 외부 API + 로컬 마스터 + 서버 추론 구조를 목표로 함
- DB는 필수 계층이 아니며, 필요 시 `prediction_logs`만 저장
- 마스터 데이터 자동 갱신과 DB 저장은 현재 선행 작업이 아님

## 2. 현재 프로젝트 구조

```text
fastapi/
├── app/
│   ├── api/
│   │   ├── beta_station_data.py
│   │   ├── ddri_admin.py
│   │   ├── ddri_stations.py
│   │   ├── ddri_user.py
│   │   └── weather.py
│   ├── core/
│   │   └── runtime_config.py
│   ├── database/
│   │   ├── connection.py
│   │   └── connection_local.py
│   ├── utils/
│   │   ├── security.py
│   │   ├── weather_mapping.py
│   │   └── weather_service.py
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

## 4. 구현 상태

### 구현 완료

- 베타 고정 6개 스테이션 기반 사용자 조회 API
- 베타 고정 6개 스테이션 기반 관리자 위험 목록 API
- 베타 고정 6개 스테이션 기반 마스터 목록 API
- Open-Meteo 기반 일별/단건 날씨 API
- Swagger / ReDoc 노출
- CORS 개발 설정
- 환경변수 기반 `beta` / `live` 모드 분기
- 기본 입력 검증과 인젝션 방지 유틸

### 아직 미완료

- 외부 실시간 재고 API 연동
- `live` 모드용 실제 마스터 로딩 구조
- 예측 모델 런타임 연결
- 예외/폴백 응답 규칙 정교화
- 입력 오류 문구의 외부 노출 일반화
- 필요 시 `prediction_logs` 저장

## 5. 서비스 모드

`app/core/runtime_config.py` 기준으로 `DDRI_SERVICE_MODE`를 읽는다.

- `beta`
  - 기본값
  - 사용자/관리자/마스터 API 모두 고정 6개 스테이션 기준 응답
  - 화면에 `베타` 표기가 포함될 수 있음
- `live`
  - 운영 전환용 분기
  - 현재는 일부 목업 응답만 존재하고 실제 운영 데이터 소스는 아직 미연결

유효하지 않은 값이 들어오면 안전하게 `beta`로 폴백한다.

## 6. 실행 방법

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

- `DDRI_SERVICE_MODE=beta`: 고정 6개 베타 정책 사용
- `DDRI_SERVICE_MODE=live`: 운영 경로 사용 예정
- 현재 DB는 필수는 아니며, 추후 `prediction_logs` 저장 시 사용 가능

### 4. 서버 실행

```bash
cd fastapi
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 5. 문서 확인

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## 7. 보안 및 응답 원칙

- CORS는 `allow_credentials=False` 기준으로 설정돼 있다.
- 입력값 검증은 `app/utils/security.py`에서 수행한다.
- 현재 검증 대상:
  - `target_datetime`, `base_datetime`
  - `district_name`
  - `cluster_code`
  - `sort_by`
  - `sort_order`
  - 날씨용 날짜 형식
- 외부 응답에는 내부 예외 클래스명, traceback, SQL, raw body, 파일 경로를 노출하지 않는 것이 원칙이다.
- 다만 현재 일부 4xx 응답과 관리자 예외 응답 구조는 추가 정리 대상이다.

## 8. 데이터 계층 원칙

현재 기준:

- 실시간 재고: 외부 API 기준
- 날씨: Open-Meteo 기준
- 스테이션 마스터: 베타는 고정 6개, 운영은 추후 별도 로더 필요
- 예측 모델: 서버 로컬 런타임 연결 예정
- 마스터 데이터 자동 갱신과 DB 적재는 후순위
- 실시간 재고는 원천 조회값으로 사용하고 기본 적재 대상이 아님
- 미래 시점 재고도 현재 재고와 예측 결과의 계산값으로 취급

DB 사용:

- 현재 필수 아님
- `mysql/init_schema.sql`은 최소 스키마만 유지
- 저장 대상 후보는 `prediction_logs`

즉 현재는 전체 스테이션 마스터나 실시간 재고를 서비스 DB에 선적재하는 구조를 전제로 두지 않는다.

## 9. 날씨 API 역할

날씨는 두 층으로 사용한다.

1. 화면 표시 정보
2. 추후 모델 입력 피처 참조

현재 화면 기준 구조:

- `weekly_forecast`: 주간 일별 날씨
- `selected_forecast` 또는 단건 상세 날씨: 선택 시각 기준 정보

## 10. 문서와 코드의 연결

- 사람용 요약 명세:
  - [API_SPEC.md](/Users/cheng80/Desktop/ddri_web/docs/api/API_SPEC.md)
- OpenAPI 명세:
  - [openapi.yaml](/Users/cheng80/Desktop/ddri_web/docs/api/openapi.yaml)
- 기준 설계 문서:
  - [README.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/README.md)
  - [01_screen_design_and_scope.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/01_screen_design_and_scope.md)
  - [02_system_design.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/02_system_design.md)
  - [03_api_and_runtime_contract.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/03_api_and_runtime_contract.md)

## 11. 다음 작업

1. 보안 노출 정리 작업 수행
2. 외부 실시간 재고 API 연동 설계 확정
3. `live` 모드용 마스터 로딩 구조 확정
4. 예측 모델 런타임 연결
5. 필요 시 `prediction_logs` 저장 계약 확정
