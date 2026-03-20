# DDRI API 문서

작성일: 2026-03-20  
목적: 현재 `ddri_web`의 조회형 API 문서 위치와 유지 원칙을 정리한다.

## 문서 구성

| 파일 | 역할 |
|------|------|
| `API_SPEC.md` | 화면 기준의 사람이 읽는 요약 명세 |
| `openapi.yaml` | 도구 연동용 OpenAPI 3.0 명세 |
| `README.md` | 문서 체계와 참고 순서 안내 |

## 유지 기준

- 이 폴더는 현재 구현된 `v1` 조회 API만 다룬다.
- 설계 기준은 아래 문서를 따른다.
  - [README.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/README.md)
  - [01_screen_design_and_scope.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/01_screen_design_and_scope.md)
  - [02_system_design.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/02_system_design.md)
  - [03_api_and_runtime_contract.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/03_api_and_runtime_contract.md)
- 베타 기간에는 사용자/관리자/마스터 API 모두 고정 6개 스테이션 정책을 기준으로 문서를 유지한다.
- 현재 고정 6개는 번들 생성 대상과 동일하다: `2348`, `2335`, `2377`, `2384`, `2306`, `2375`
- 예외 상황에서도 외부 응답 문서는 내부 예외 정보, raw body, stack trace 노출을 허용하지 않는 방향으로 유지한다.

## 현재 문서 읽는 순서

1. [API_SPEC.md](/Users/cheng80/Desktop/ddri_web/docs/api/API_SPEC.md)
2. [openapi.yaml](/Users/cheng80/Desktop/ddri_web/docs/api/openapi.yaml)
3. [API_GUIDE.md](/Users/cheng80/Desktop/ddri_web/fastapi/API_GUIDE.md)

## 확인 방법

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`
- OpenAPI 검토: [Swagger Editor](https://editor.swagger.io/)에 `openapi.yaml` 로드

## 현재 범위 메모

- 구현 완료:
  - `GET /`
  - `GET /health`
  - `GET /v1/user/stations/nearby`
  - `GET /v1/admin/stations/risk`
  - `GET /v1/stations`
  - `GET /v1/weather/direct`
  - `GET /v1/weather/direct/single`
- 아직 문서상 확정만 해둔 항목:
  - 외부 실시간 재고 연동
  - 예측 런타임 연결
  - `live` 모드용 실제 마스터 로딩 경로
