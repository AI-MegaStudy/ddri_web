# DDRI 사용자 페이지 상세 설계 – 자전거 대여소 조회

작성일: 2026-03-16  
목적: 사용자용 자전거 대여소 조회 웹페이지의 위치 기반·주소 검색·시간대 선택·길찾기 기능을 상세 정의한다.

---

## 1. 화면 목적

> **사용자가 이 사이트를 이용하는 이유**

1. **내 근처** 또는 **지정된 주소 근처**에서, **지정 시간대**에 자전거가 얼마나 있는지 **예측**해서 보여주는 것
2. 가능하면: 사용자 위치(또는 지정 주소)에서 **지정 대여소까지 길찾기** 페이지를 보여주는 것

### 핵심 UI (필수)

| UI | 용도 |
|----|------|
| **내 위치 찾기** | Geolocation API → 위경도 → 근처 대여소 조회 |
| **주소 찾기** | 주소 검색 → 위경도 → 근처 대여소 조회 |
| **시간대 선택** | 예측 기준 시각 지정 (날짜·시간) |

---

## 2. 위치 검색 방식

### 2.1 현 위치 기반 (Geolocation)

| 항목 | 내용 |
|------|------|
| **입력** | 브라우저 Geolocation API `getCurrentPosition()` |
| **출력** | 위경도 (latitude, longitude) |
| **용도** | 사용자 중심으로 가까운 대여소 거리 계산 |

**동작 흐름:**

1. 페이지 진입 시 또는 "현 위치로 검색" 버튼 클릭 시 위치 요청
2. 사용자 허용 시 위경도 획득
3. 161개 대여소 중 위경도 기준 거리 계산 (Haversine 등)
4. 거리 순 정렬 후 상위 N개 표시

**예외 처리:**

- 위치 권한 거부: `주소 검색 버튼` 또는 `수동 입력` 안내
- 위치 획득 실패: 재시도 버튼 또는 주소 검색 유도

### 2.2 주소 기반 검색

| 항목 | 내용 |
|------|------|
| **패키지** | [kpostal_plus](https://github.com/pyowonsik/kpostal_plus) |
| **기능** | 카카오 우편번호 서비스 기반 주소 검색 |
| **출력** | 주소·우편번호·위경도 (kakaoLatitude, kakaoLongitude) |

**동작 흐름:**

1. "주소 검색" 버튼 클릭 → `KpostalPlusView` 화면 표시
2. 사용자가 주소 선택 → `postCode`, `address`, `kakaoLatitude`, `kakaoLongitude` 등 callback 수신
3. 위경도로 161개 대여소 거리 계산
4. 거리 순 정렬 후 상위 N개 표시

**kpostal_plus 설정:**

- `kakaoKey`: Kakao JavaScript API 키 (웹에서 위경도 사용 시 필요)
- `callback`: `(Kpostal result) => { lat, lng }` 저장 후 대여소 검색 API 호출

---

## 3. 대여소 목록 표시

### 3.1 데이터 소스

| 항목 | 경로 | 용도 |
|------|------|------|
| 대여소 마스터/위경도 | `cheng80/api_output/ddri_full161_station_api_mapping_table.csv` | 161개 스테이션, gangnam_lat, gangnam_lon |
| 실시간 재고 | OA-15493 bikeList | current_bike_stock |
| 예측 수요 | 서버 예측 API | predicted_rental_count, predicted_remaining_bikes |

### 3.2 거리 계산

- **입력**: 사용자 중심 좌표 (lat, lng)
- **출력**: 각 대여소까지의 거리 (m 또는 km)
- **알고리즘**: Haversine formula 또는 `geolocator` 패키지

### 3.3 표시 순서

- 거리 가까운 순 (최근접 우선)
- 기본 표시 개수: 10~20개 (설정 가능)

### 3.4 대여소 카드 표시 항목

| 항목 | 필수 | 비고 |
|------|------|------|
| 대여소명 | ✓ | gangnam_station_name |
| 거리 | ✓ | "약 150m" 등 |
| 현재 자전거 수 | ✓ | 실시간 API |
| 예상 잔여 자전거 수 | ✓ | current - predicted_rental |
| 대여 가능 여부 배지 | ✓ | availability_level |
| 주소 | △ | gangnam_address |
| 운영 상태 | △ | 실시간 비노출 시 "정보 없음" |

---

## 4. 화면 구성

### 4.1 레이아웃

```
┌─────────────────────────────────────────────────────────┐
│  상단 네비게이션 (사용자 | 관리자 | 통계)                    │
├─────────────────────────────────────────────────────────┤
│  [내 위치 찾기]  [주소 찾기]  [날짜·시간 선택]  ← 3가지 필수  │
│  (선택된 위치: 위경도 또는 주소 표시)                        │
├─────────────────────────────────────────────────────────┤
│  가까운 대여소 목록 (거리순, 지정 시간대 기준 예측)            │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐                     │
│  │ 대여소 1 │ │ 대여소 2 │ │ 대여소 3 │  ...               │
│  │ 150m    │ │ 320m    │ │ 450m    │                     │
│  │ 대여가능 │ │ 보통    │ │ 부족    │  [길찾기] 버튼      │
│  └─────────┘ └─────────┘ └─────────┘                     │
└─────────────────────────────────────────────────────────┘
```

### 4.2 검색/입력 영역 (3가지 필수)

1. **내 위치 찾기** 버튼
   - Geolocation API 호출
   - 성공 시 위치 아이콘 + "현재 위치 기준" 표시

2. **주소 찾기** 버튼
   - `Navigator.push` → `KpostalPlusView` 화면 (또는 카카오 우편번호)
   - 선택 완료 시 "주소: OOO" 표시

3. **시간대 선택**
   - 날짜·시간 선택기 (예측 기준 시각)
   - 기본값: 현재 시각 또는 오늘 18:00 등

4. **선택된 위치 표시**
   - 위경도 또는 주소 텍스트
   - "다시 검색" 링크

### 4.3 대여소 목록 영역

- 카드형 또는 리스트형 (정보 풍부하게)
- 거리·대여 가능 여부 시각적 구분
- 스크롤 또는 페이지네이션

### 4.4 길찾기 (선택, 가능하면 제공)

- **목적**: 사용자 위치(또는 지정 주소) → 지정 대여소까지 경로 안내
- **구현**: 카카오맵/네이버맵/구글맵 길찾기 URL로 새 탭 열기
  - 예: `https://map.kakao.com/link/to/대여소명,위도,경도` 또는 `naver://map/...`
- **트리거**: 대여소 카드/행의 "길찾기" 버튼 또는 아이콘

### 4.5 지도·리스트 UX (상세)

- **지도**: 단일 지도 1개, 원형 반경, 마커로 대여소 표시 (카드당 개별 지도 없음)
- **모바일**: 지도 상단 + 카드 리스트 하단
- **데스크탑**: 지도 좌측 + 리스트 우측 2분할

→ 상세: [10_ddri_user_page_map_ux_spec.md](10_ddri_user_page_map_ux_spec.md)

---

## 5. 의존성

### 5.1 Flutter 패키지

| 패키지 | 용도 | 버전 |
|--------|------|------|
| kpostal_plus | 주소 검색 (카카오 우편번호) | ^1.0.0 |
| geolocator | 현 위치 위경도 (선택) | - |
| (또는) web: Geolocation API | 브라우저 직접 호출 | - |

### 5.2 외부 서비스

| 서비스 | 용도 |
|--------|------|
| Kakao Postcode | 카카오 우편번호 서비스 (kpostal_plus 내장) |
| Kakao Geolocation API | 주소→위경도 변환 (kpostal_plus kakaoKey 사용 시) |

**Kakao API 키:**

- [Kakao Developer](https://developers.kakao.com/)에서 앱 생성
- JavaScript 키 발급
- 웹 도메인 등록 (localhost, 배포 도메인)

---

## 6. API 요구사항

### 6.1 클라이언트 → 서버

**가까운 대여소 조회 (예상):**

```
GET /api/stations/nearby?lat=37.5&lng=127.0&target_datetime=2026-03-18T18:00:00&limit=20
```

- `lat`, `lng`: 사용자 위치 (내 위치 또는 주소 검색 결과)
- `target_datetime`: 예측 기준 시각 (ISO8601, 사용자가 선택한 시간대)
- `limit`: 표시 개수

또는

- 클라이언트에서 161개 마스터 위경도 + 거리 계산
- 서버는 `target_datetime` 기준 실시간 재고·예측만 조회

### 6.2 서버 응답 (대여소 단건)

기존 `01_ddri_flutter_web_service_preparation.md` 정의:

```json
{
  "station_id": 2348,
  "station_name": "포스코사거리(기업은행)",
  "current_bike_stock": 4,
  "predicted_rental_count": 9.1,
  "predicted_remaining_bikes": 0.0,
  "bike_availability_flag": true,
  "availability_level": "low",
  "operational_status": "operational"
}
```

**추가 필요:**

- `latitude`, `longitude` (거리 계산용)
- `distance_m` (서버에서 계산 시)

---

## 7. 구현 우선순위

1. **1단계**: 주소 검색 (kpostal_plus) + 161개 마스터 위경도 + 거리 계산 (클라이언트)
2. **2단계**: 현 위치 검색 (Geolocation)
3. **3단계**: 실시간 재고·예측 API 연동

---

## 8. 참조

- kpostal_plus: https://github.com/pyowonsik/kpostal_plus
- 대여소 매핑: `cheng80/api_output/ddri_full161_station_api_mapping_table.csv`
- API 운영 규칙: `cheng80/02_ddri_api_operational_rules.md`
