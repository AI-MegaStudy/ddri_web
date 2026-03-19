# 02 Web Service Final

현재 웹서비스 문서는 아래 3개를 기준 정본으로 사용한다.

## 현재 기준 문서

1. [01_screen_design_and_scope.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/01_screen_design_and_scope.md)
   - 서비스 범위
   - 사용자/관리자 화면 설계
   - 반응형 및 Stitch 참조 기준

2. [02_system_design.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/02_system_design.md)
   - 시스템 아키텍처
   - 데이터 흐름
   - ERD/DB 최소 설계
   - 로컬 마스터, 외부 API, 예측 로그 저장 전략

3. [03_api_and_runtime_contract.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/03_api_and_runtime_contract.md)
   - 화면에서 호출하는 API 계약
   - 예측 런타임 입력/출력
   - 외부 API 연동과 폴백 규칙

## 문서 재정의 원칙

- 문서는 가능한 한 적게 유지한다.
- 화면 설계와 시스템 설계를 분리한다.
- DB는 기본 저장소가 아니라 선택적 영속 계층으로 다룬다.
- 실시간 데이터는 외부 API를 기준 진실로 본다.
- 정적 마스터는 웹/앱 선탑재 + API 최신화 구조를 기본으로 한다.

## 현재 서비스 전제

- 로그인 없음
- 입력 없는 모니터링 중심 웹
- 사용자 설정, 즐겨찾기, 통계 저장은 1차 범위에서 제외
- 예측 결과는 화면 조회용으로 계산하고, 필요 시 예측 로그만 저장
- 현재 베타 운영 중에는 고정 6개 스테이션 노출 정책을 사용할 수 있으며, 운영 전환 시 `DDRI_SERVICE_MODE=live` 기준으로 재검토한다

## 레거시 문서

기존 상세 문서는 `legacy/` 아래 참고용 레거시 문서로 남겨둔다.

- 기존 문서를 즉시 삭제하지는 않는다.
- 새 설계와 충돌할 경우 이 README에 적힌 3개 문서를 우선한다.
- 추후 필요 시 레거시 문서는 정리 또는 archive 이동한다.

## Stitch 자료 처리 원칙

- Stitch 관련 문서는 별도 축으로 분리하지 않는다.
- 화면 설계 기준 문서 [01_screen_design_and_scope.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/01_screen_design_and_scope.md) 안에서 직접 링크한다.
- 유지 대상은 다음과 같다.
  - [stitch](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/stitch)
  - [stitch_export](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/stitch/stitch_export)
  - [09_stitch_design_application_guide.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/stitch/09_stitch_design_application_guide.md)
  - [11_stitch_mcp_progress_and_references.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/stitch/11_stitch_mcp_progress_and_references.md)
  - 필요 시 레거시 화면 상세 문서는 `legacy/` 경로에서 참조한다.
