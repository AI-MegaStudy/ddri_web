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

### 진행 중

- [ ] 관리자 페이지 레이아웃과 실제 동작 안정화
  - [x] 목록 렌더는 복구됨
  - [x] 태블릿 스택 레이아웃에서 `날씨 -> 요약 -> 리스트 -> 예외 -> 지도` 순서 복구
  - [ ] 관리자 실제 지도 표시가 모든 브레이크포인트에서 안정적으로 보이는지 검증 필요
  - [ ] 보조 패널/스택 레이아웃에서 지연 렌더(`isSupplementReady`, `isMapReady`)가 과도한지 재검토 필요

### 아직 미완료

- [ ] 사용자 `/user`, 관리자 `/admin` 오류·빈 상태·폴백 상태 전체 보안 노출 점검
- [ ] 사용자 화면 Stitch 기준 최종 정합 점검
- [ ] 관리자 화면 Stitch 기준 최종 정합 점검
- [ ] 외부 실시간 재고 API 연동
- [ ] 예측 런타임 연결
- [ ] `live` 모드용 마스터 로딩 원본과 갱신 절차 확정
- [ ] `prediction_logs` 스키마 확정 여부 결정

## 최근 반영 내용

### 문서 및 API

- [x] `docs/api/README.md` 갱신
- [x] `docs/api/API_SPEC.md` 갱신
- [x] `docs/api/openapi.yaml` 갱신
- [x] `fastapi/API_GUIDE.md` 갱신
- [x] ERD / DBML 문서 갱신

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

### 관리자 페이지

- [x] 실제 날씨 API 기반 7일 구조 바인딩
- [x] 주간 날씨 카드 스타일을 사용자 쪽과 유사하게 정리
- [x] 날씨 섹션 접기/펼치기 추가
- [x] 긴 리스트에서 하단 지도/예외가 밀리지 않도록 데스크탑 보조 패널 구조 도입
- [x] 실제 마커 지도 도입
- [x] 리스트 선택과 지도 중심 이동 연결
- [x] 모바일/태블릿 카드 리스트 선택 상태 렌더 오류 수정
- [ ] 지도 표시 안정화 및 레이아웃 최종 정리

## 현재 우선순위

1. 관리자 페이지 지도 표시 안정화
2. 관리자 페이지 태블릿/모바일/데스크탑 레이아웃 최종 점검
3. `/user`, `/admin` 오류·빈 상태·폴백 상태 보안 노출 재점검
4. 베타 6개 스테이션 선정 기준과 원본 위치 문서화
5. 외부 실시간 재고 API 연동 설계 확정
6. 예측 런타임 연결
7. 마스터 데이터 로딩·갱신·저장 전략 재검토

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
- [ ] 사용자 nearby API가 고정 6개가 아닌 운영 조회 경로를 사용하도록 교체
- [ ] 관리자 risk API가 운영 계산 경로를 사용하도록 교체
- [ ] 스테이션 마스터 API가 운영 마스터 원본을 사용하도록 교체
- [ ] `베타` 표기와 베타 안내 문구가 운영 모드에서 제거되는지 확인
- [ ] 운영 모드의 예외 처리와 보안 노출 원칙 재점검
- [ ] 운영 전환 후 문서 전체 갱신

## 작업 원칙

- 이 파일은 웹서비스 실행 플랜만 다룬다.
- ML 연구/발표/리포트 작업은 포함하지 않는다.
- 예외 상황에서도 UI에는 사용자용 안전 문구만 표시한다.
- 내부 오류 정보, stack trace, raw body, 내부 식별자 등 공격 단서는 화면에 노출하지 않는다.
