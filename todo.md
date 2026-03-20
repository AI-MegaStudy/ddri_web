# DDRI Next Chat TODO

목적: 다음 대화에서 현재 상태를 빠르게 이어받고, 가장 먼저 해야 할 작업부터 바로 진행하기 위한 인수인계 문서.

## 다음 대화 시작 시 먼저 할 일

1. `plan.md` 읽기
2. `todo.md` 읽기
3. 관리자 페이지 현재 상태를 먼저 확인
4. 그다음 사용자 페이지와 문서 정합성 확인

## 현재 기준 커밋

- 최근 커밋: `f25676d`
- 커밋 메시지: `Refine admin dashboard flow and API docs`

## 현재 상태 한 줄 요약

- 사용자 페이지는 거의 정리됐고, 관리자 페이지는 목록/날씨/요약은 복구됐지만 지도 표시 안정화가 가장 시급하다.

## 지금 확정된 사실

### 사용자 페이지 `/user`

- 반응형 레이아웃은 정리된 상태다.
- 낮은 높이에서 overflow 나던 문제는 스크롤 폴백으로 정리했다.
- 주간 날씨 카드 overflow도 정리했다.
- 선택 시각 날씨 카드 스타일은 관리자 카드 톤에 맞췄다.
- 날씨 컨테이너는 접고 펼칠 수 있다.

### 관리자 페이지 `/admin`

- 관리자 API 호출은 정상이다.
- 콘솔 기준 `관리자 API 응답 수신`, `파싱 완료`, `관리자 목록` 로그까지 정상 확인됐다.
- 이전에 목록이 안 뜨던 핵심 원인은 `admin_station_list.dart`의 GetX `Obx` 오용이었다.
- 그 오류는 수정했고, 지금은 목록이 다시 뜬다.
- 관리자 날씨는 실제 API 기반 구조로 연결돼 있다.
- 관리자 리스트는 필터 응답에 맞춰 그려진다.
- 실제 마커 지도도 붙였지만, 현재는 레이아웃/표시 안정성 검증이 덜 끝난 상태다.

## 지금 가장 중요한 미해결 이슈

### 1. 관리자 지도 표시 안정화

- 태블릿 폭에서 목록은 뜨는데 지도 표시가 기대대로 항상 나오지 않는 구간이 있었다.
- 문제 분리 과정에서 `isSupplementReady`, `isMapReady` 지연 렌더 로직이 들어갔다.
- 현재 레이아웃은 다시 복구했지만, 이 지연 렌더 구조가 정말 필요한지 재검토해야 한다.
- 필요하면 관리자 지도는 사용자 지도 패턴처럼 더 단순하게 다시 정리한다.

### 2. 관리자 반응형 최종 점검

- 현재 목표 순서:
  - 필터
  - 날씨
  - 요약 카드
  - 리스트
  - 예외
  - 지도
- 데스크탑에서는 `리스트 + 보조 패널` 구성이어야 한다.
- 태블릿/모바일에서는 스택 구성이어야 한다.
- 방금 레이아웃 회귀를 한 번 겪었기 때문에 다시 실기기 폭 기준으로 확인이 필요하다.

### 3. 오류·빈 상태·폴백 상태 보안 노출 점검

- 내부 예외 문자열, raw body, stack trace, 내부 식별자 노출은 정리하는 방향으로 이미 수정했다.
- 하지만 `/user`, `/admin` 전체 상태를 화면 기준으로 다시 훑는 작업은 아직 남아 있다.

## 다음 대화에서 우선 볼 파일

### 최우선

- `lib/view/admin_view.dart`
- `lib/view/admin/admin_map_placeholder.dart`
- `lib/view/admin/admin_station_list.dart`
- `lib/vm/admin_page_controller.dart`

### 그다음

- `lib/view/admin/admin_weather_section.dart`
- `lib/view/admin/admin_exceptions_section.dart`
- `lib/view/user_view.dart`
- `lib/view/user/user_weather_section.dart`
- `lib/vm/user_page_controller.dart`
- `lib/common/api/ddri_api_client.dart`
- `lib/common/api/models/station_models.dart`

### 백엔드 확인 필요 시

- `fastapi/app/api/ddri_admin.py`
- `fastapi/app/api/beta_station_data.py`
- `fastapi/app/api/ddri_user.py`
- `fastapi/app/api/weather.py`
- `fastapi/app/utils/security.py`

## 다음 대화에서 바로 진행할 우선 작업

1. 관리자 페이지를 먼저 열고 지도 표시 여부부터 확인
2. 관리자 지도 지연 렌더 구조(`isSupplementReady`, `isMapReady`) 유지 여부 판단
3. 필요하면 관리자 지도 렌더를 더 단순화
4. 관리자 반응형 최종 정렬 점검
5. `/user`, `/admin` 오류·빈 상태·폴백 상태 보안 노출 점검

## 이미 끝난 작업이라 다시 하지 말 것

- `docs/api/README.md`, `docs/api/API_SPEC.md`, `docs/api/openapi.yaml`, `fastapi/API_GUIDE.md` 재정리
- 관리자 예외 UI의 `station_id` 직접 노출 제거
- Flutter `ApiException` raw body 노출 제거
- 사용자 날씨 카드 overflow 수정
- 사용자 페이지 낮은 높이 overflow 수정
- 관리자 목록 GetX improper use 예외 수정

## 주의할 점

- 관리자 페이지 문제를 분리하려고 레이아웃 순서를 임시로 바꿨다가 회귀가 생긴 적이 있다.
- 다음 수정에서는 데스크탑과 태블릿/모바일 레이아웃을 분리해서 생각해야 한다.
- 지도 문제를 잡을 때 목록/날씨/요약까지 같이 흔들지 않는 것이 중요하다.
- 현재 워크트리가 깨진 상태는 아니고, 최근 커밋까지 존재한다. 새 대화에서는 먼저 현재 화면을 재현해 보고 들어가는 게 맞다.

## 다음 대화 권장 시작 프롬프트

```text
plan.md와 todo.md를 먼저 읽고 현재 상태를 요약한 뒤, 관리자 지도 안정화부터 진행해줘.
```
