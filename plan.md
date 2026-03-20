# DDRI 웹서비스 실행 플랜

작성일: 2026-03-20  
갱신일: 2026-03-20  
목적: `ddri_web` 구현 작업을 웹서비스 기준으로만 관리한다.

## 기준 문서

- [docs/02_web_service_final/README.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/README.md)
- [docs/02_web_service_final/01_screen_design_and_scope.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/01_screen_design_and_scope.md)
- [docs/02_web_service_final/02_system_design.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/02_system_design.md)
- [docs/02_web_service_final/03_api_and_runtime_contract.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/03_api_and_runtime_contract.md)
- [docs/02_web_service_final/legacy/12_ddri_responsive_breakpoints_and_layouts.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/legacy/12_ddri_responsive_breakpoints_and_layouts.md)

## 서비스 범위

- 비로그인 공개 웹
- 사용자 페이지 `/user`
- 관리자 페이지 `/admin`
- 조회 전용 서비스
- 외부 API + 로컬 마스터 + 서버 추론 구조
- DB는 필요 시 `prediction_logs`만 저장

## 현재 상태 요약

### 완료

- [x] `/user`, `/admin` 기본 라우트와 공통 `AppScaffold` 구성
- [x] 베타 기간 6개 스테이션 노출 정책 반영
- [x] API 문서 체계 재정리
- [x] FastAPI 입력 검증 및 안전한 오류 문구 정리
- [x] Flutter `ApiException` raw body 노출 제거
- [x] 관리자 예외 UI의 내부 식별자 노출 제거
- [x] 사용자 페이지 반응형 레이아웃 정리
- [x] 사용자 페이지 날씨 카드/선택 시각 카드 스타일 정리
- [x] 사용자/관리자 날씨 섹션 접기/펼치기 지원
- [x] 관리자 페이지 실제 날씨 API 연동
- [x] 관리자 페이지 리스트 선택 상태와 지도 연동용 좌표 응답 연결
- [x] 관리자 지도 플레이스홀더를 실제 `flutter_map` 기반으로 교체
- [x] 관리자 목록 렌더 중 GetX `Obx` 오용으로 인한 예외 수정
- [x] 서울시 `bikeList` 실시간 재고 API 연동
- [x] top6 대상 `joblib` 예측 런타임 연결
- [x] `beta`/`live` 모두 더미 응답 제거 및 실제 재고+예측 경로 연결
- [x] Flutter/FastAPI 디버그 로그 토글 및 실시간 재고·예측값 로그 추가
- [x] 사용자 지도 스크롤 충돌 완화
- [x] 사용자 페이지 전체 스크롤 구조 재정리
- [x] 사용자/관리자 지도 `+ / - / 초기화` 버튼 추가
- [x] 사용자/관리자 지도 휠 줌 비활성화 및 페이지 스크롤 우선 처리
- [x] 사용자/관리자 지도 줌 범위 고정 및 버튼 비활성화 처리
- [x] 사용자 반경 필터를 `전체보기 / 300m / 500m / 1km` 라디오형 선택으로 정리
- [x] 사용자 `전체보기`는 반경 미적용, `300m/500m/1km`는 실제 반경 필터로 연결
- [x] 관리자 행정동 필터를 현재 top6 기준 5개 동으로 축소
- [x] 관리자 위험도 UI를 대수 중심 표현으로 정리
- [x] 관리자 `긴급만` 기준을 `예상 잔여 5대 이하`로 전환
- [x] 관리자 대수 표기를 올림 정수 기준으로 정리

### 진행 중

- [ ] top6 임시 런타임 기준 앱 화면 E2E 검증
  - [x] 사용자/관리자 API 응답은 실제 재고+예측값으로 연결됨
  - [x] 사용자 지도와 리스트 기본 연동은 동작함
  - [x] 관리자 지도와 리스트 기본 연동은 동작함
  - [ ] 사용자 화면 실제 기기/브라우저 기준 스크롤과 지도 조작 검증 필요
  - [ ] 관리자 화면 실제 기기/브라우저 기준 브레이크포인트 검증 필요
  - [ ] 관리자 보조 패널/스택 레이아웃에서 지연 렌더(`isSupplementReady`, `isMapReady`) 재검토 필요

### 아직 미완료

- [ ] 사용자 `/user`, 관리자 `/admin` 오류·빈 상태·폴백 상태 전체 보안 노출 점검
- [ ] 사용자 화면 Stitch 기준 최종 정합 점검
- [ ] 관리자 화면 Stitch 기준 최종 정합 점검
- [ ] 사용자 지도 검색 조건 변경 시 재센터링/포커스 재선정 안정화
- [ ] `live` 모드용 마스터 로딩 원본과 갱신 절차 확정
- [ ] `prediction_logs` 저장 필요 여부와 저장 시점 확정

## 최근 반영 내용

### 예측 런타임 사전 분석

- [x] `/Users/cheng80/Desktop/ddri_work/hmw3/Note/hmw_top5_station_trends_2023_2025.ipynb` 확인
- [x] 상기 노트북은 `station_hour_bike_flow_2023_2025.csv`에서 이용량 기준 상위 스테이션을 뽑아 시각화만 수행하며, 직접적인 학습/저장은 하지 않음을 확인
- [x] 실제 모델 구조는 `hmw2332.ipynb` 및 `generate_top20_station_suite.py` 기준으로 확인
- [x] 현재 예측 단위는 `station_id`별 `rental_count`, `return_count` 2개 Ridge 모델임을 확인
- [x] 통합 test `R^2` 기준 상위 6개 스테이션 후보 확인: `2348`, `2335`, `2377`, `2384`, `2306`, `2375`
- [x] FastAPI 배포용 권장 패키징 단위 정리:
  - [x] 권장: 현재 top6 연결용으로 스테이션당 1개 `joblib` 번들 파일로 묶기 -> 총 `6개`
  - [x] 비권장 대안: 타깃별 개별 저장(`rental_count`, `return_count`) -> 총 `12개`

### 문서 및 API

- [x] `docs/api/README.md` 갱신
- [x] `docs/api/API_SPEC.md` 갱신
- [x] `docs/api/openapi.yaml` 갱신
- [x] `fastapi/API_GUIDE.md` 갱신
- [x] ERD / DBML 문서 갱신
- [x] 현재 `live`도 top6 임시 런타임이라는 문서 정리

### 보안 노출 정리

- [x] 관리자 예외 스테이션 UI에서 `station_id` 직접 노출 제거
- [x] 예외 스테이션 영역을 집계형 문구로 변경
- [x] Flutter `ApiException`에서 raw `response.body` 직접 노출 제거
- [x] 컨트롤러/UI에서 서버 응답 원문을 화면에 직접 바인딩하지 않도록 정리
- [x] FastAPI 4xx/날씨 오류 문구 일반화
- [ ] 오류·빈 상태·폴백 상태 전수 점검

### 사용자 페이지

- [x] 높이 부족 시 스크롤 가능한 레이아웃으로 폴백
- [x] 날씨 카드 overflow 수정
- [x] 선택 시각 날씨 카드를 관리자 스타일에 가깝게 정리
- [x] 날씨 섹션 접기/펼치기 추가
- [x] 반경 필터를 `전체보기 / 300m / 500m / 1km` 라디오형으로 정리
- [x] `전체보기`와 실제 반경 필터 동작을 API와 일치시킴
- [x] 지도 휠 줌 비활성화
- [x] 지도 `+ / - / 초기화` 버튼 추가
- [x] 페이지 전체 스크롤 구조 재정리
- [ ] 새 검색 결과 기준 지도 중심/포커스 재정렬 최종 확인

### 관리자 페이지

- [x] 실제 날씨 API 기반 7일 구조 바인딩
- [x] 주간 날씨 카드 스타일을 사용자 쪽과 유사하게 정리
- [x] 날씨 섹션 접기/펼치기 추가
- [x] 긴 리스트에서 하단 지도/예외가 밀리지 않도록 데스크탑 보조 패널 구조 도입
- [x] 실제 마커 지도 도입
- [x] 리스트 선택과 지도 중심 이동 연결
- [x] 모바일/태블릿 카드 리스트 선택 상태 렌더 오류 수정
- [x] 지도 휠 줌 비활성화
- [x] 지도 `+ / - / 초기화` 버튼 추가
- [x] 행정동 필터를 현재 5개 동 기준으로 조정
- [x] 위험도 표현을 `예상 잔여`, `부족 예상` 중심으로 조정
- [ ] 지도 표시 안정화 및 레이아웃 최종 정리

## 현재 우선순위

1. top6 임시 런타임에 대한 실제 앱 E2E 스모크 테스트
2. 관리자 페이지 태블릿/모바일/데스크탑 레이아웃 최종 점검
3. 사용자 지도 검색 조건 변경 시 재센터링/포커스 재선정 안정화
4. `/user`, `/admin` 오류·빈 상태·폴백 상태 보안 노출 재점검
5. 베타 6개 스테이션 선정 기준과 원본 위치 문서화
6. 차기 운영용 마스터 로딩 원본과 해제 절차 확정
7. 최종 모델 단위 결정 전 DB 저장 필요 여부 판단
8. 마스터 데이터 로딩·갱신·저장 전략 재검토

## DB 연동 판단 기준

- 현재 단계에서 DB는 필수 선행 작업이 아니다.
- 지금 서비스는 조회형 구조이며, 실시간 재고와 예측 결과는 요청 시점 계산으로 충분하다.
- 따라서 DB는 `prediction_logs` 같은 최소 로그 저장이 필요해질 때 붙이는 것이 맞다.

### DB를 붙이는 시점

1. top6 임시 런타임의 앱/서버 E2E 검증이 끝난 뒤
2. 어떤 예측 이력을 남길지 계약이 정리된 뒤
3. `station별` 유지인지, `cluster별` 또는 `hybrid`로 바뀌는지 모델 단위가 한 번 정리된 뒤

### 현재 기준 권장 순서

1. 앱과 서버가 top6 런타임으로 안정 동작하는지 먼저 검증
2. 운영 확장 시 모델 단위와 마스터 로딩 원본 확정
3. 그 다음 `prediction_logs` 최소 저장만 MySQL에 연결
4. 저장 대상은 원천 실시간 재고 전체가 아니라 예측 결과 메타데이터만 유지

## 다음 작업 시 바로 볼 파일

### Flutter

- `lib/view/admin_view.dart`
- `lib/view/admin/admin_map_placeholder.dart`
- `lib/view/admin/admin_station_list.dart`
- `lib/view/admin/admin_weather_section.dart`
- `lib/view/admin/admin_exceptions_section.dart`
- `lib/vm/admin_page_controller.dart`
- `lib/view/user_view.dart`
- `lib/view/user/user_weather_section.dart`
- `lib/vm/user_page_controller.dart`
- `lib/common/api/ddri_api_client.dart`
- `lib/common/api/models/station_models.dart`

### FastAPI

- `fastapi/app/api/ddri_admin.py`
- `fastapi/app/api/ddri_user.py`
- `fastapi/app/api/weather.py`
- `fastapi/app/api/beta_station_data.py`
- `fastapi/app/utils/security.py`
- `fastapi/app/utils/weather_service.py`

## Live 전환 체크리스트

- [ ] `DDRI_SERVICE_MODE=live` 전환 전 운영 데이터 소스 준비 완료
- [ ] 사용자 nearby API가 top6 임시 경로가 아닌 차기 운영 조회 경로를 사용하도록 교체
- [ ] 관리자 risk API가 운영 계산 경로를 사용하도록 교체
- [ ] 스테이션 마스터 API가 운영 마스터 원본을 사용하도록 교체
- [ ] 최종 모델 단위 확정 후 `prediction_logs` 저장 여부 결정
- [ ] 저장이 필요하면 MySQL `prediction_logs` 테이블 실제 연결 및 쓰기 경로 추가
- [ ] `베타` 표기와 베타 안내 문구가 운영 모드에서 제거되는지 확인
- [ ] 운영 모드의 예외 처리와 보안 노출 원칙 재점검
- [ ] 최종 모델 단위 확정 후 문서 전체 갱신

## 작업 원칙

- 이 파일은 웹서비스 실행 플랜만 다룬다.
- ML 연구/발표/리포트 작업은 포함하지 않는다.
- 예외 상황에서도 UI에는 사용자용 안전 문구만 표시한다.
- 내부 오류 정보, stack trace, raw body, 내부 식별자 등 공격 단서는 화면에 노출하지 않는다.
