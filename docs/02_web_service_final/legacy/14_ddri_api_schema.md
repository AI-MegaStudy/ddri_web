# DDRI API 스키마 (화면 기능 기준)

작성일: 2026-03-18  
목적: 사용자·관리자 화면 기능에 맞춘 API 요청/응답 스키마를 정의한다.

---

## 1. 저장 기능 필요 여부

### 결론: **웹 앱 저장 기능 불필요**

| 구분 | 내용 |
|------|------|
| **사용자 페이지** | 위치·시간 입력 → 조회 → 결과 표시. 로그인·즐겨찾기 없음 |
| **관리자 페이지** | 날짜/시간·필터 입력 → 조회 → 결과 표시. 재배치는 외부 프로세스 |
| **API 성격** | **모두 조회(Read) 전용**. POST/PUT/DELETE 없음 |

### 백엔드 저장 vs 웹 앱 저장

| 항목 | 필요 여부 | 설명 |
|------|-----------|------|
| **서버 측 저장** | ✓ 필요 | 실시간 재고 캐시, 예측 결과, 스테이션 마스터 등. API가 데이터를 제공하려면 서버가 저장/캐싱해야 함 |
| **웹 앱 저장** | ✗ 불필요 | 사용자가 "저장" 버튼을 누르는 기능 없음. 세션·즐겨찾기·메모 등 저장 대상 없음 |

---

## 2. API 목록 (조회 전용)

| API | 메서드 | FastAPI 경로 | 용도 |
|-----|--------|--------------|------|
| `GET /v1/user/stations/nearby` | GET | ddri_user.router | 사용자 페이지: 근처 대여소 조회 |
| `GET /v1/admin/stations/risk` | GET | ddri_admin.router | 관리자 페이지: 재배치 판단 목록 조회 |
| `GET /v1/stations` | GET | ddri_stations.router | 스테이션 마스터 조회 (161개) |
| `GET /v1/weather/direct` | GET | weather.router | 날씨 예보 (Open-Meteo) |

---

## 3. 사용자 페이지 API

### 3.1 `GET /api/user/stations/nearby`

**용도**: 내 위치 또는 지정 주소 근처 대여소 목록 (거리순, 지정 시간대 예측)

**요청 (Query)**

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `lat` | number | ✓ | 위도 |
| `lng` | number | ✓ | 경도 |
| `target_datetime` | string | ✓ | 예측 기준 시각 (ISO 8601, 예: `2026-03-18T18:00:00+09:00`) |
| `limit` | number | | 반환 개수 (기본 20) |
| `radius_m` | number | | 반경(m). 미지정 시 전체 중 거리순 |

**응답**

```json
{
  "target_datetime": "2026-03-18T18:00:00+09:00",
  "user_location": { "lat": 37.5012, "lng": 127.0396 },
  "items": [
    {
      "station_id": 2348,
      "station_name": "포스코사거리(기업은행)",
      "address": "서울특별시 강남구 테헤란로 501",
      "latitude": 37.50723267,
      "longitude": 127.05685425,
      "distance_m": 150,
      "current_bike_stock": 4,
      "predicted_rental_count": 9.1,
      "predicted_remaining_bikes": 0.0,
      "bike_availability_flag": true,
      "availability_level": "low",
      "operational_status": "operational"
    }
  ],
  "exceptions": [
    { "station_id": 2314, "reason": "실시간 비노출" }
  ]
}
```

**필드 설명**

| 필드 | 타입 | 설명 |
|------|------|------|
| `distance_m` | number | 사용자 위치에서 대여소까지 거리(m) |
| `current_bike_stock` | number | 실시간 보유 대수 |
| `predicted_rental_count` | number | 해당 시간대 예측 대여량 |
| `predicted_remaining_bikes` | number | 예상 잔여 수 (current - predicted 또는 더 정교한 식) |
| `bike_availability_flag` | boolean | 대여 가능 여부 |
| `availability_level` | string | `"sufficient"` \| `"normal"` \| `"low"` |
| `operational_status` | string | `"operational"` \| `"비노출"` \| `"비활성"` |

---

## 4. 관리자 페이지 API

### 4.1 `GET /api/admin/stations/risk`

**용도**: 시간대별 재배치 판단 목록 (전체 또는 필터)

**요청 (Query)**

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `base_datetime` | string | ✓ | 기준 시각 (ISO 8601) |
| `urgent_only` | boolean | | true 시 위험 대여소만 |
| `district_name` | string | | 행정동 필터 (예: `역삼동`) |
| `cluster_code` | string | | 지역 특성 필터 (예: `cluster00`) |
| `sort_by` | string | | `risk_score` \| `reallocation_priority` \| `stock_gap` |
| `sort_order` | string | | `asc` \| `desc` |

**응답**

```json
{
  "base_datetime": "2026-03-18T18:00:00+09:00",
  "summary": {
    "total_count": 161,
    "risk_count": 23,
    "exception_count": 3,
    "avg_risk_score": 0.42
  },
  "items": [
    {
      "station_id": 2348,
      "station_name": "포스코사거리(기업은행)",
      "district_name": "삼성동",
      "cluster_code": "cluster01",
      "current_bike_stock": 4,
      "predicted_demand": 9.1,
      "stock_gap": -6.1,
      "risk_score": 0.51,
      "reallocation_priority": 1,
      "operational_status": "operational"
    }
  ],
  "exceptions": [
    { "station_id": 2314, "reason": "실시간 비노출" },
    { "station_id": 2323, "reason": "실시간 비노출" },
    { "station_id": 3628, "reason": "실시간 비노출" }
  ]
}
```

**필드 설명**

| 필드 | 타입 | 설명 |
|------|------|------|
| `predicted_demand` | number | 해당 시간대 예측 수요(대여량) |
| `stock_gap` | number | current_bike_stock - predicted_demand (음수면 부족) |
| `risk_score` | number | 0~1, 높을수록 위험 |
| `reallocation_priority` | number | 1, 2, 3... (1이 최우선) |

---

## 5. 예외 스테이션 규칙

| 상황 | API 응답 처리 |
|------|---------------|
| 실시간 비노출 (2314, 2323, 3628) | `items`에 포함하지 않고 `exceptions` 배열에만 포함 |
| 비활성 스테이션 | `operational_status: "비활성"`으로 `items`에 포함 또는 `exceptions` 처리 (정책 확정 필요) |
| 실시간 API 장애 | 해당 스테이션은 `exceptions`에 포함, `reason`에 "실시간 정보 없음" 등 |

---

## 6. 에러 응답

```json
{
  "error": {
    "code": "INVALID_PARAMETER",
    "message": "lat, lng are required"
  }
}
```

| code | 설명 |
|------|------|
| `INVALID_PARAMETER` | 필수 파라미터 누락 또는 형식 오류 |
| `SERVICE_UNAVAILABLE` | 실시간 API 또는 예측 서비스 장애 |
| `NOT_FOUND` | 해당 조건에 맞는 데이터 없음 |

---

## 7. 데이터 소스 (서버 측)

| API | 서버 데이터 소스 |
|-----|------------------|
| 사용자 조회 | `stations` + `realtime_station_stock` + `station_demand_forecasts` |
| 관리자 조회 | `stations` + `station_risk_snapshots` 또는 실시간 조합 계산 |
| 예외 목록 | `station_api_mappings` (match_status, exception_reason) |

---

## 8. 서버·DB 설정

FastAPI 백엔드는 MySQL을 사용하며, `fastapi/.env`에서 DB 연결 정보를 읽는다.

| 환경 변수 | 용도 |
|-----------|------|
| `DB_HOST` | MySQL 호스트 |
| `DB_USER` | DB 사용자 |
| `DB_PASSWORD` | DB 비밀번호 |
| `DB_NAME` | DB 이름 (ddri_db) |
| `DB_PORT` | 포트 (13306) |

- **경로**: `fastapi/.env` (Git 커밋 제외)
- **연결 모듈**: `fastapi/app/database/connection.py` — `.env` 로드 후 사용 권장

---

## 9. 참조 문서

| 문서 | 용도 |
|------|------|
| docs/api/openapi.yaml | OpenAPI 3.0 명세서 |
| docs/api/README.md | API 명세 양식 안내 |
| 04_ddri_database_design.md | 테이블 구조 |
| 08_ddri_user_page_spec_detail.md | 사용자 화면 입력/출력 |
| 13_ddri_admin_page_plan.md | 관리자 화면 입력/출력 |
| 01_ddri_flutter_web_service_preparation.md | 기존 응답 예시 |
