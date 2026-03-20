# DDRI API 명세서

작성일: 2026-03-20  
갱신일: 2026-03-20  
목적: 현재 `ddri_web`에서 실제 사용 중인 조회형 API를 화면 기준으로 정리한다.

## 문서 기준

- API 버전: `v1`
- 인증: 없음
- 응답 형식: JSON
- 서비스 성격: 비로그인 공개 조회 웹
- 현재 기본 모드: `DDRI_SERVICE_MODE=beta`
- 문서 기준 구현 위치:
  - `fastapi/app/main.py`
  - `fastapi/app/api/ddri_user.py`
  - `fastapi/app/api/ddri_admin.py`
  - `fastapi/app/api/ddri_stations.py`
  - `fastapi/app/api/weather.py`

## 공통 원칙

- 사용자/관리자/스테이션 API는 베타 기간 동안 동일한 고정 6개 스테이션을 기준으로 응답한다.
- 응답에는 `service_mode`, `list_mode` 같은 운영 상태 필드를 포함할 수 있다.
- 화면 바인딩용 응답만 외부에 노출하고 모델 내부 피처 전체는 반환하지 않는다.
- 예외 상황에서도 raw exception, stack trace, SQL, 내부 파일 경로 같은 문자열은 외부 응답에 포함하지 않는다.
- 날씨는 화면 표시용 정보와 추후 모델 입력용 참조를 함께 고려한 구조로 유지한다.

## 1. API 목록

| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/` | API 정보 |
| GET | `/health` | 헬스 체크 |
| GET | `/v1/user/stations/nearby` | 사용자 위치 기준 스테이션 조회 |
| GET | `/v1/admin/stations/risk` | 관리자 위험도 목록 조회 |
| GET | `/v1/stations` | 스테이션 마스터 목록 조회 |
| GET | `/v1/weather/direct` | 일별 날씨 목록 조회 |
| GET | `/v1/weather/direct/single` | 특정 시각 기준 날씨 1건 조회 |

## 2. 사용자 API

### `GET /v1/user/stations/nearby`

용도:
- 사용자 페이지 `/user`의 메인 리스트와 지도 바인딩
- 지정 위치 기준 거리순 스테이션 목록 조회
- 선택 시각 기준 날씨와 주간 날씨를 함께 제공

#### 요청 파라미터

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `lat` | number | ✓ | 위도 |
| `lng` | number | ✓ | 경도 |
| `target_datetime` | string | ✓ | ISO 8601 기준 시각 |
| `limit` | integer | | 반환 개수, 기본 `20`, 최대 `50` |
| `radius_m` | integer | | 반경(m), 현재 베타 응답에서는 정렬 보조 의미만 가짐 |

#### 현재 응답 구조

```json
{
  "target_datetime": "2026-03-20T18:00:00+09:00",
  "service_mode": "beta",
  "list_mode": "beta_fixed_6",
  "user_location": {
    "lat": 37.5012,
    "lng": 127.0396
  },
  "weather": {
    "weekly_forecast": [
      {
        "weather_datetime": "2026-03-20T00:00:00+09:00",
        "weather_type": "맑음",
        "weather_low": 4.0,
        "weather_high": 13.0,
        "icon_url": "https://openweathermap.org/img/wn/01d@2x.png"
      }
    ],
    "selected_forecast": {
      "weather_datetime": "2026-03-20T18:00:00+09:00",
      "weather_type": "구름많음",
      "weather_low": 6.0,
      "weather_high": 14.0,
      "icon_url": "https://openweathermap.org/img/wn/03d@2x.png"
    }
  },
  "items": [
    {
      "station_id": 2348,
      "station_name": "포스코사거리(기업은행) 베타",
      "address": "서울 강남구 테헤란로 인근",
      "latitude": 37.507,
      "longitude": 127.056,
      "distance_m": 210,
      "current_bike_stock": 9,
      "predicted_rental_count": 4.5,
      "predicted_remaining_bikes": 4.5,
      "bike_availability_flag": true,
      "availability_level": "normal",
      "operational_status": "operational",
      "service_tag": "베타"
    }
  ],
  "exceptions": []
}
```

#### 메모

- 베타 모드에서는 실제 주변 전체 조회가 아니라 고정 6개를 거리순으로 재정렬해 반환한다.
- `target_datetime` 형식 검증 실패 시 현재 구현은 `400`을 반환한다.
- `exceptions`는 현재 베타 응답에서는 빈 배열이다.

## 3. 관리자 API

### `GET /v1/admin/stations/risk`

용도:
- 관리자 페이지 `/admin`의 요약 카드, 표, 예외 섹션 바인딩
- 기준 시각의 부족 위험 목록 조회

#### 요청 파라미터

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `base_datetime` | string | ✓ | ISO 8601 기준 시각 |
| `urgent_only` | boolean | | 위험 스테이션만 필터링 |
| `district_name` | string | | 행정동 필터 |
| `cluster_code` | string | | 지역 특성 필터 |
| `sort_by` | string | | `risk_score`, `reallocation_priority`, `stock_gap` |
| `sort_order` | string | | `asc`, `desc` |

#### 현재 응답 구조

```json
{
  "base_datetime": "2026-03-20T18:00:00+09:00",
  "service_mode": "beta",
  "list_mode": "beta_fixed_6",
  "weather": {
    "weekly_forecast": [
      {
        "weather_datetime": "2026-03-20T00:00:00+09:00",
        "weather_type": "맑음",
        "weather_low": 4.0,
        "weather_high": 13.0,
        "icon_url": "https://openweathermap.org/img/wn/01d@2x.png"
      }
    ],
    "selected_forecast": {
      "weather_datetime": "2026-03-20T18:00:00+09:00",
      "weather_type": "구름많음",
      "weather_low": 6.0,
      "weather_high": 14.0,
      "icon_url": "https://openweathermap.org/img/wn/03d@2x.png"
    }
  },
  "summary": {
    "total_count": 6,
    "risk_count": 3,
    "exception_count": 0,
    "avg_risk_score": 0.51
  },
  "items": [
    {
      "station_id": 2348,
      "station_name": "포스코사거리(기업은행) 베타",
      "district_name": "역삼동",
      "cluster_code": "cluster00",
      "current_bike_stock": 4,
      "predicted_demand": 8.0,
      "stock_gap": -4.0,
      "risk_score": 0.76,
      "reallocation_priority": 1,
      "operational_status": "operational",
      "service_tag": "베타"
    }
  ],
  "exceptions": []
}
```

#### 메모

- 베타 모드에서는 동일한 6개 스테이션만 사용한다.
- `summary.exception_count`는 현재 베타 기준 `0`이다.
- 예외 정보는 `station_id` 대신 집계형 항목으로만 노출한다.
- `live` 모드 목업 응답의 예외 예시는 아래와 같다.

```json
[
  {
    "reason": "실시간 데이터가 일부 준비되지 않았습니다.",
    "count": 3
  }
]
```

## 4. 스테이션 마스터 API

### `GET /v1/stations`

용도:
- 화면용 기본 스테이션 정보 조회
- 사용자/관리자 공용 마스터 목록 바인딩

#### 요청 파라미터

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `district_name` | string | | 행정동 필터 |
| `cluster_code` | string | | 지역 특성 필터 |

#### 현재 응답 구조

```json
{
  "service_mode": "beta",
  "list_mode": "beta_fixed_6",
  "items": [
    {
      "station_id": 2348,
      "api_station_id": "ST-2348",
      "station_name": "포스코사거리(기업은행) 베타",
      "district_name": "역삼동",
      "address": "서울 강남구 테헤란로 인근",
      "latitude": 37.507,
      "longitude": 127.056,
      "cluster_code": "cluster00",
      "operational_status": "operational",
      "service_tag": "베타"
    }
  ],
  "total_count": 6
}
```

#### 메모

- 베타 모드에서는 운영용 전체 마스터를 반환하지 않는다.
- `live` 모드용 실제 마스터 원본 위치와 로딩 구조는 아직 확정되지 않았다.

## 5. 날씨 API

### `GET /v1/weather/direct`

용도:
- 일별 예보 배열 조회
- 사용자/관리자 주간 날씨 UI 구성

#### 요청 파라미터

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `lat` | number | ✓ | 위도 |
| `lon` | number | ✓ | 경도 |
| `start_date` | string | | `YYYY-MM-DD`, 없으면 오늘 포함 기본 범위 반환 |

#### 응답 형태

```json
{
  "results": [
    {
      "weather_datetime": "2026-03-20T00:00:00",
      "weather_type": "맑음",
      "weather_low": 4.0,
      "weather_high": 13.0,
      "precipitation_probability_max": 10,
      "icon_url": "https://..."
    }
  ]
}
```

### `GET /v1/weather/direct/single`

용도:
- 특정 시각에 가장 가까운 상세 날씨 1건 조회
- 화면의 선택 시각 상세 날씨 UI 구성

#### 요청 파라미터

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `lat` | number | ✓ | 위도 |
| `lon` | number | ✓ | 경도 |
| `target_datetime` | string | | ISO 8601 기준 시각 |
| `target_date` | string | | 하위 호환용 `YYYY-MM-DD`, `target_datetime` 없을 때 사용 |

#### 응답 형태

```json
{
  "result": {
    "weather_datetime": "2026-03-20T18:00:00",
    "weather_type": "구름많음",
    "weather_low": 6.0,
    "weather_high": 14.0,
    "temperature": 12.1,
    "precipitation_probability": 20,
    "icon_url": "https://..."
  }
}
```

## 6. 현재 미완료 항목

- 외부 실시간 재고 API 연동
- 예측 모델 런타임 연결
- `live` 모드용 실제 마스터 로딩 구조 확정
- 입력 오류 문구와 예외 응답의 외부 노출 문구 일반화
- 관리자 `exceptions` 구조의 보안형 응답 정리
