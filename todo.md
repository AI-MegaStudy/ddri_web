# DDRI Next Chat TODO

목적: 다음 대화에서 현재 상태를 빠르게 이어받고, 가장 먼저 해야 할 작업부터 바로 진행하기 위한 인수인계 문서.

## 다음 대화 시작 시 먼저 할 일

1. `plan.md` 읽기
2. `todo.md` 읽기
3. top6 임시 런타임 기준 화면과 API가 같은 값을 쓰는지 먼저 확인
4. 그다음 관리자/사용자 화면의 남은 UI 안정화와 문서 정합성 확인

## 현재 기준 커밋

- 최근 커밋: `f25676d`
- 커밋 메시지: `Refine admin dashboard flow and API docs`

## 현재 상태 한 줄 요약

- top6 임시 런타임은 실제 재고+예측으로 동작 중이고, 남은 핵심은 앱 E2E 검증과 사용자/관리자 지도·레이아웃 마감이다.

## 지금 확정된 사실

### 사용자 페이지 `/user`

- 반응형 레이아웃은 정리된 상태다.
- 낮은 높이에서 overflow 나던 문제는 페이지 전체 스크롤 구조로 정리했다.
- 주간 날씨 카드 overflow도 정리했다.
- 선택 시각 날씨 카드 스타일은 관리자 카드 톤에 맞췄다.
- 날씨 컨테이너는 접고 펼칠 수 있다.
- 조회 필터는 `전체보기 / 300m / 500m / 1km` 4개가 라디오처럼 동작한다.
- `전체보기`는 반경 미적용, `300m / 500m / 1km`는 실제 반경 필터가 적용된다.
- 지도는 `flutter_map` 기반이며, 휠 줌은 꺼져 있고 `+ / - / 초기화` 버튼이 있다.
- 지도/리스트 기본 포커스 연동은 동작한다.
- 다만 검색 조건 변경 시 지도 중심과 포커스가 항상 새 결과에 자연스럽게 맞는지는 추가 확인이 필요하다.

### 관리자 페이지 `/admin`

- 관리자 API 호출은 정상이다.
- 실제 실시간 재고 + `joblib` 예측값이 관리자 응답에 반영된다.
- 관리자 날씨는 실제 API 기반 구조로 연결돼 있다.
- 행정동 필터는 현재 top6 기준 5개 동만 노출한다.
- `긴급만` 기준은 이제 `예상 잔여 5대 이하`다.
- 위험도 숫자 중심 표기는 줄이고, `예상 잔여`, `부족 예상` 중심으로 바꿨다.
- 지도는 휠 줌이 꺼져 있고 `+ / - / 초기화` 버튼이 있다.
- 실제 마커 지도와 리스트 선택 연동은 붙어 있지만, 브레이크포인트별 표시 안정성은 추가 검증이 필요하다.

### 백엔드 / 런타임

- 서울시 `bikeList` 실시간 재고 연동 완료
- top6 대상 `joblib` 번들 6개 생성 및 로드 완료
- `beta`와 `live` 모두 더미 응답은 제거됐고, 현재는 같은 top6 임시 런타임을 사용
- 디버그 로그는 Flutter/FastAPI 모두 토글 가능
- DB 저장은 아직 미연결이며, `prediction_logs`는 보류 상태

## 지금 가장 중요한 미해결 이슈

### 1. top6 임시 런타임 E2E 검증

- 실제 브라우저 기준으로 `/user`, `/admin` 화면이 API 응답과 같은 값을 쓰는지 다시 봐야 한다.
- 디버그 로그가 있으므로 실시간 재고/예측값이 화면과 일치하는지 바로 비교 가능하다.

### 2. 관리자 지도/레이아웃 최종 안정화

- 태블릿 폭과 데스크탑에서 지도, 리스트, 보조 패널 배치가 기대대로 유지되는지 확인 필요
- `isSupplementReady`, `isMapReady` 지연 렌더 구조가 과한지 재검토 필요

### 3. 사용자 지도 검색 결과 동기화

- 리스트 클릭 포커스는 동작
- 다만 검색 조건 변경 시 지도 중심/포커스가 새 결과 기준으로 더 자연스럽게 맞는지 확인 필요

### 4. 오류·빈 상태·폴백 상태 보안 노출 점검

- 내부 예외 문자열, raw body, stack trace, 내부 식별자 노출은 대부분 정리됨
- 하지만 `/user`, `/admin` 전체 상태를 실제 화면 기준으로 다시 훑는 작업은 아직 남아 있다

## 다음 대화에서 우선 볼 파일

### 최우선

- `lib/view/admin_view.dart`
- `lib/view/admin/admin_map_placeholder.dart`
- `lib/view/admin/admin_station_list.dart`
- `lib/view/user_view.dart`
- `lib/view/user/user_map_section.dart`
- `lib/vm/admin_page_controller.dart`
- `lib/vm/user_page_controller.dart`

### 그다음

- `lib/view/admin/admin_weather_section.dart`
- `lib/view/admin/admin_exceptions_section.dart`
- `lib/view/user/user_weather_section.dart`
- `lib/common/api/ddri_api_client.dart`
- `lib/common/api/models/station_models.dart`

### 백엔드 확인 필요 시

- `fastapi/app/api/ddri_admin.py`
- `fastapi/app/api/beta_station_data.py`
- `fastapi/app/api/ddri_user.py`
- `fastapi/app/api/weather.py`
- `fastapi/app/utils/security.py`

## 다음 대화에서 바로 진행할 우선 작업

1. `/user`, `/admin`를 실제로 열고 디버그 로그와 화면 값을 대조
2. 관리자 지도/브레이크포인트 표시 안정성 확인
3. 사용자 검색 조건 변경 시 지도 중심/포커스 동기화 확인
4. 관리자 지도 지연 렌더 구조(`isSupplementReady`, `isMapReady`) 유지 여부 판단
5. `/user`, `/admin` 오류·빈 상태·폴백 상태 보안 노출 점검

## 이미 끝난 작업이라 다시 하지 말 것

- `docs/api/README.md`, `docs/api/API_SPEC.md`, `docs/api/openapi.yaml`, `fastapi/API_GUIDE.md` 재정리
- 관리자 예외 UI의 `station_id` 직접 노출 제거
- Flutter `ApiException` raw body 노출 제거
- 사용자 날씨 카드 overflow 수정
- 사용자 페이지 낮은 높이 overflow 수정
- 관리자 목록 GetX improper use 예외 수정
- top6 실시간 재고 + `joblib` 예측 런타임 연결
- 사용자/관리자 지도 `+ / - / 초기화` 버튼 추가
- 사용자/관리자 지도 휠 줌 비활성화
- 사용자 반경 필터를 `전체보기 / 300m / 500m / 1km` 라디오형으로 정리
- 관리자 행정동 필터 5개 동 기준 정리
- 관리자 대수 표기 올림 정수 처리

## 주의할 점

- 관리자 페이지 문제를 분리하려고 레이아웃 순서를 임시로 바꿨다가 회귀가 생긴 적이 있다.
- 다음 수정에서는 데스크탑과 태블릿/모바일 레이아웃을 분리해서 생각해야 한다.
- 지도 문제를 잡을 때 목록/날씨/요약까지 같이 흔들지 않는 것이 중요하다.
- 현재 워크트리는 더러울 수 있으므로 기존 수정사항을 되돌리지 말 것
- DB 저장은 아직 보류 상태이므로, 지금 대화 기준 핵심은 저장이 아니라 top6 임시 런타임 검증이다

## 다음 대화 권장 시작 프롬프트

```text
plan.md와 todo.md를 먼저 읽고 현재 상태를 요약한 뒤, top6 임시 런타임 기준으로 /user와 /admin 화면 E2E 확인부터 진행해줘.
```
