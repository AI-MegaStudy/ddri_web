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
- 베타 운영 정책: 예측 모델 완성 전까지 실제 강남 161개 또는 2016년 기준 전체 따릉이 스테이션 대신, 선별된 6개 스테이션만 사용자/관리자 화면에 동일하게 노출
- 현재 모델 가정: 베타 6개는 성능 상위 6개 스테이션(`2348`, `2335`, `2377`, `2384`, `2306`, `2375`) 기준으로 맞추는 방향
- 운영 전환 키: `fastapi/.env`의 `DDRI_SERVICE_MODE=beta|live`로 베타/운영 모드를 전환
- 우선순위 조정: 마스터 데이터 API 자동 갱신과 마스터 저장 자체는 후순위로 미루고, 베타 운영·예측 런타임·보안 정리를 먼저 진행
- 보안 원칙: 예외/오류 상황에서도 화면에는 내부 예외 정보, stack trace, raw body, 내부 식별자 등 공격 단서가 노출되면 안 됨

## 현재 합의된 핵심 사항

### 사용자 페이지

- 섹션 순서: `검색 → 날씨 → 지도 → 리스트`
- 날씨 호출은 기존처럼 유지하되, 대여소 리스트는 베타 기간 동안 위치 기반 전체 조회 대신 고정 6개만 노출
- 태블릿은 `900px 이상`이면 세로여도 좌우 분할
- 모바일/태블릿 세로는 `SingleChildScrollView`
- 지도 없을 때는 플레이스홀더 표시 + 진입 시 현 위치 자동 로드
- 지도 높이: `42% viewport`, `280~450px`
- 모바일 날씨 카드: `140px`, `4열 compact`

### 관리자 페이지

- 현재는 제어 영역, 요약 카드, 표, 예외 스테이션, 맵 플레이스홀더까지 구현
- 베타 기간에는 사용자 화면과 동일한 6개 스테이션만 표에 노출하고 각 항목에 `베타` 표기를 붙임
- 실제 지도, 날씨 UI, 상세 보안 노출 정리는 다음 작업 범위

## 현재 모델 합의 초안

- 참조 자료:
  - `/Users/cheng80/Desktop/report_clean_copy.pdf`
  - `/Users/cheng80/Desktop/ddri_work/hmw3/Note/hmw_station.ipynb`
  - `/Users/cheng80/Desktop/ddri_work/hmw3/Data/top20_station_combined_test_r2_ranking.csv`
- 상위 6개 스테이션을 1차 모델 적용 대상으로 본다.
  - `2348` 포스코사거리(기업은행)
  - `2335` 3호선 매봉역 3번출구앞
  - `2377` 수서역 5번출구
  - `2384` 자곡사거리
  - `2306` 압구정역 2번 출구 옆
  - `2375` 수서역 1번출구 앞
- 현재 모델은 `stock` 직접 예측형이 아니라 시간대별 `rental_count`, `return_count` 예측형으로 이해한다.
- 미래 재고는 `현재 재고 - 예측 rental_count + 예측 return_count` 계산값으로 다룬다.
- 서버 내부 피처 초안:
  - `year`, `month`, `day`, `weekday`, `hour`, `day_type`
  - `base_value`, `month_weight`, `year_weight`, `hour_weight`
  - `pattern_prior`, `corrected_pattern_prior`
- `year_weight`는 프론트 입력이 아니라 서버 내부 보정값이다.
- `year_weight`는 프론트 입력이 아니라 서버 내부 변수화된 고정값이다.
- 현재 단계에서는 현재 테스트 기준값을 고정 사용하고, 추가 보정계수는 도입하지 않는다.
- 차후 운영상 관리 필요가 확인되면 그때 별도 테이블과 보정 계수 도입을 검토한다.
- 최종 운영 모델 계약은 실제 ML 산출물 포맷을 받은 뒤 확정한다.

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
5. 베타 6개를 상위 6개 스테이션 기준으로 확정할지 결정하고 데이터 교체 여부 반영
6. 외부 실시간 재고 API 연동 설계 확정
7. 예측 런타임 연결
8. 마스터 데이터 로딩·갱신·저장 전략 재검토
9. ML 산출물 포맷 수신 후 모델 입력/출력 계약 최종 확정

## 보안 노출 정리 작업 상세

- 관리자 예외 스테이션 UI에서 `station_id` 직접 노출 제거
- 예외 스테이션 영역을 집계형/설명형 문구로 변경
- Flutter `ApiException`에서 raw `response.body` 직접 노출 방지
- 컨트롤러/UI에서 `e.toString()` 또는 서버 응답 원문을 화면에 바인딩하지 않도록 점검
- FastAPI 4xx 입력 오류 문구 일반화
- `/user`, `/admin`의 오류·빈 상태·폴백 상태 재점검

## 마스터 데이터 관련 판단

- 현재 단계에서는 마스터 데이터 API 자동 갱신 기능을 필수 선행 작업으로 두지 않는다.
- 마스터 데이터 자체를 DB에 저장하는 작업도 후순위로 둔다.
- 당장은 베타 6개 고정 목록과 예측 런타임 연결이 우선이다.
- DB 최소 스키마(`prediction_logs`)는 이 판단에 직접 영향받지 않는다.
- 다만 실제 운영 전환 시 `live` 모드가 참조할 마스터 원본 위치와 로딩 방식은 별도로 확정해야 한다.
- 실시간 재고는 서울시 API 기준 데이터이므로 우리 서비스가 별도 적재·누적할 대상이 아니다.
- 미래 시점 재고도 현재 재고와 예측 결과의 계산값으로 다루며, 기본 저장 대상은 아니다.
- 저장을 검토할 값은 예측 로그 또는 예측 결과 이력뿐이다.

## Live 전환 체크리스트

베타 종료 시 아래 항목을 함께 점검한다.

1. `fastapi/.env`의 `DDRI_SERVICE_MODE`를 `beta`에서 `live`로 변경
2. `live` 모드에서 사용할 실제 스테이션 마스터 원본 파일 또는 로더 위치 확정
3. 사용자 `/v1/user/stations/nearby`가 고정 6개가 아니라 실제 전체/대상 스테이션 조회를 사용하도록 교체
4. 관리자 `/v1/admin/stations/risk`가 실제 재고·예측·위험도 계산 결과를 사용하도록 교체
5. `/v1/stations`가 운영용 마스터 목록을 반환하도록 교체
6. `service_tag=베타` 및 베타 안내 문구가 `live` 모드에서 노출되지 않는지 확인
7. 관리자 요약 카드의 전체 개수·위험 개수·예외 개수가 실제 운영 값과 일치하는지 확인
8. 예외 스테이션 처리 규칙이 운영 데이터 기준에서도 안전 문구만 노출하는지 확인
9. 마스터 데이터 저장이 필요한지 다시 판단하고, 필요 시에도 최소 스키마 원칙을 유지할지 검토
10. 문서에서 베타 정책 문구를 운영 기준으로 갱신

## prediction_logs 관련 메모

- `prediction_logs` 스키마는 아직 확정하지 않는다.
- ML 모델 산출물 형식이 나온 뒤 정의한다.
- 정의 확정 시 `fastapi/mysql/init_schema.sql`과 ERD 문서를 함께 갱신한다.
- 현재 저장 후보는 실시간 재고 원본이 아니라 예측 결과와 메타데이터다.
- 후보 필드 예시:
  - `prediction_time`
  - `target_time`
  - `station_id`
  - `predicted_rental_count`
  - `predicted_return_count`
  - `predicted_remaining_bikes`
  - `model_version`
  - 필요 시 `year_weight_version`
- 추가 보정계수 테이블/로그는 현재 범위에 넣지 않는다.

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
