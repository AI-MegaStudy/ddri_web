# 10 FastAPI 모듈 디자인 발표 스피치 보고서

## 1. 발표 개요
- 발표 주제: `07_fastapi_module_design.drawio` 기반 FastAPI 단독 모듈 구조
- 대상: 백엔드/프론트엔드/인프라 공통
- 권장 발표 시간: 6~8분
- 발표 목표: API 라우터 계층, 유틸리티 계층, DB/외부 연동 흐름을 한 번에 설명

## 2. 한 줄 핵심 메시지
FastAPI 백엔드는 `main -> api routers -> core/utils/database -> external systems`의 단방향 흐름으로 구성되어 있고, 베타/운영 모드 전환이 공통 설정으로 관리됩니다.

## 3. 발표 스크립트 (발표자가 읽는 멘트)
안녕하세요. FastAPI 단독 모듈 디자인을 설명드리겠습니다.  
진입점은 `app/main.py`이며, 여기서 FastAPI 앱 생성, CORS 설정, 라우터 등록이 이루어집니다.

라우터는 네 가지입니다.  
`weather.py`, `ddri_user.py`, `ddri_admin.py`, `ddri_stations.py`가 각각 `/v1/weather`, `/v1/user`, `/v1/admin`, `/v1/stations`를 담당합니다.

`weather.py`는 Open-Meteo 연동 전용입니다.  
`/direct`, `/direct/single` 엔드포인트를 제공하고, 입력값은 `security.py` 검증 함수를 통해 보호됩니다.

`ddri_user.py`는 사용자 조회 API입니다.  
핵심은 `/stations/nearby`이며, 내부적으로 `beta_station_data.py`를 사용해 결과를 만들고  
예측 로그는 `save_prediction_logs_safely()`로 비동기 성격의 best-effort 저장을 수행합니다.

`ddri_admin.py`는 관리자 조회 API입니다.  
`/stations/risk`에서 필터/정렬 조건을 검증한 뒤, 목록/요약/날씨를 조합해서 반환합니다.  
관리자 날씨는 `WeatherService`로 실제 조회를 시도하고 실패 시 안전 폴백을 제공합니다.

`ddri_stations.py`는 스테이션 마스터 목록 API입니다.  
현재 베타 기간 운영 정책에 맞춰 고정 집합을 필터링하는 구조를 사용합니다.

중간 계층에서 중요한 모듈은 `beta_station_data.py`입니다.  
고정 스테이션 데이터와 런타임 예측, 실시간 재고, 로그 생성까지 조합해  
사용자/관리자 응답 모델을 만드는 핵심 허브 역할을 합니다.

공통 설정은 `runtime_config.py`로 분리되어 있습니다.  
`DDRI_SERVICE_MODE` 환경변수로 beta/live 전환을 통제하고, `DDRI_DEBUG_LOG`로 로그 레벨을 제어합니다.

`prediction_runtime.py`는 모델 번들(`joblib`) 로더입니다.  
스테이션별 번들을 읽어 예측치를 계산하고, 잔여 재고 추정치까지 산출합니다.

외부 연동은 세 갈래입니다.  
날씨는 Open-Meteo, 자전거 실시간 재고는 서울 Open API, 로그 저장은 MySQL입니다.  
DB 저장 실패가 API 본 흐름을 깨지 않도록 로그 저장은 안전 호출 방식으로 설계되어 있습니다.

정리하면, 현재 FastAPI는 라우터 책임이 명확하고, 검증/설정/예측/외부연동이 모듈화되어  
기능 확장 시 영향 범위를 제한하기 좋은 구조입니다.

## 4. 예상 질문과 답변
Q. 왜 라우터에서 직접 서비스를 많이 호출하나요?  
A. 현재는 기능 단위 모듈 분리가 우선이며, 트래픽 확장 시 서비스 계층을 추가 분리하기 쉽게 구성했습니다.

Q. 베타 고정 데이터는 언제 제거되나요?  
A. `runtime_config.py`의 모드 전환 정책에 따라 live 전환 시 점진적으로 대체할 수 있게 설계되어 있습니다.

Q. 로그 저장 실패 시 데이터 정합성 문제는 없나요?  
A. 조회 API의 가용성을 우선하기 위해 best-effort 저장이며, 실패는 경고 로그로 남겨 추적합니다.

## 5. 마무리 멘트
FastAPI 모듈 디자인의 핵심은 책임 분리와 안전한 폴백입니다.  
다음 단계에서는 live 모드 확장, DB 쿼리 파라미터 바인딩 고도화, 관측성 지표 추가를 진행하겠습니다.
