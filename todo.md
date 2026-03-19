# DDRI Next Chat TODO

목적: 긴 대화 이후 신규 대화로 넘어갈 때, 현재 상태와 다음 작업을 빠르게 이어받기 위한 인수인계 문서.  
원칙: 이 문서는 사용자가 이후 대화에서 계속 갱신을 요청할 수 있는 작업 기준 문서다.

## 시작 전에 먼저 볼 문서

신규 대화에서 시작하면 아래 순서로 먼저 확인한다.

1. `plan.md`
2. `docs/02_web_service_final/README.md`
3. `docs/02_web_service_final/01_screen_design_and_scope.md`
4. `docs/02_web_service_final/02_system_design.md`
5. `docs/02_web_service_final/03_api_and_runtime_contract.md`
6. 필요 시 `docs/02_web_service_final/legacy/12_ddri_responsive_breakpoints_and_layouts.md`

## 현재 기준 상태

- 최근 기준 커밋: `c047a4e`
- 사용자 페이지 `/user`: 반응형 레이아웃과 화면 구성은 거의 완료 상태
- 관리자 페이지 `/admin`: 기본 UI는 구성됐지만 날씨 UI와 실제 지도 연동은 아직 미완료
- 보안 원칙: 예외/오류 상황에서도 화면에는 내부 예외 정보, stack trace, raw body, 내부 식별자 등 공격 단서가 노출되면 안 됨

## 현재 합의된 핵심 사항

### 사용자 페이지

- 섹션 순서: `검색 → 날씨 → 지도 → 리스트`
- 태블릿은 `900px 이상`이면 세로여도 좌우 분할
- 모바일/태블릿 세로는 `SingleChildScrollView`
- 지도 없을 때는 플레이스홀더 표시 + 진입 시 현 위치 자동 로드
- 지도 높이: `42% viewport`, `280~450px`
- 모바일 날씨 카드: `140px`, `4열 compact`

### 관리자 페이지

- 현재는 제어 영역, 요약 카드, 표, 예외 스테이션, 맵 플레이스홀더까지 구현
- 실제 지도, 날씨 UI, 상세 보안 노출 정리는 다음 작업 범위

## 다음 대화에서 우선 확인할 파일

### Flutter

- `lib/view/user_view.dart`
- `lib/view/user/user_map_section.dart`
- `lib/view/user/user_weather_section.dart`
- `lib/view/user/user_search_area.dart`
- `lib/view/user/user_station_list.dart`
- `lib/view/user/user_station_card.dart`
- `lib/view/admin_view.dart`
- `lib/view/admin/admin_exceptions_section.dart`
- `lib/view/admin/admin_map_placeholder.dart`
- `lib/vm/user_page_controller.dart`
- `lib/vm/admin_page_controller.dart`
- `lib/common/api/ddri_api_client.dart`
- `lib/common/api/models/station_models.dart`
- `lib/core/design_token.dart`

### FastAPI

- `fastapi/app/api/ddri_user.py`
- `fastapi/app/api/ddri_admin.py`
- `fastapi/app/api/weather.py`
- `fastapi/app/utils/security.py`
- `fastapi/app/utils/weather_service.py`
- `fastapi/app/main.py`

## 지금 남아 있는 우선 TODO

1. `docs/api/`와 `fastapi/API_GUIDE.md`를 새 문서 체계 기준으로 정리
2. 보안 노출 정리 작업 수행
3. 관리자 페이지 주간/기준 시각 날씨 UI 추가 여부 결정 및 구현
4. 실제 백엔드 응답 기준 화면 바인딩 정리
5. 외부 실시간 재고 API 연동 설계 확정
6. 로컬 마스터 JSON 구조 확정
7. 예측 런타임 연결

## 보안 노출 정리 작업 상세

- 관리자 예외 스테이션 UI에서 `station_id` 직접 노출 제거
- 예외 스테이션 영역을 집계형/설명형 문구로 변경
- Flutter `ApiException`에서 raw `response.body` 직접 노출 방지
- 컨트롤러/UI에서 `e.toString()` 또는 서버 응답 원문을 화면에 바인딩하지 않도록 점검
- FastAPI 4xx 입력 오류 문구 일반화
- `/user`, `/admin`의 오류·빈 상태·폴백 상태 재점검

## 다음 대화에서 권장 시작 프롬프트

아래처럼 요청하면 바로 이어서 진행하기 쉽다.

```text
todo.md와 plan.md를 먼저 읽고 현재 상태를 요약한 뒤, 가장 우선순위 높은 작업부터 진행해줘.
```

또는

```text
todo.md 기준으로 보안 노출 정리 작업부터 진행해줘.
```

## 운영 규칙

- 신규 대화에서는 먼저 `todo.md`와 `plan.md`를 함께 확인한다.
- 구현 전에 현재 코드와 문서 기준이 충돌하는지 먼저 점검한다.
- 이 문서는 사용자가 요청할 때마다 최신 진행 상황에 맞게 갱신한다.
