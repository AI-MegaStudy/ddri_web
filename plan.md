# DDRI 웹서비스 실행 플랜

작성일: 2026-03-20  
갱신일: 2026-03-17  
목적: `ddri_web` 구현 작업을 웹서비스 기준으로만 관리한다.

## 기준 문서

- [12_ddri_responsive_breakpoints_and_layouts.md](docs/02_web_service_final/legacy/12_ddri_responsive_breakpoints_and_layouts.md) (반응형 레이아웃)
- [README.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/README.md)
- [01_screen_design_and_scope.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/01_screen_design_and_scope.md)
- [02_system_design.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/02_system_design.md)
- [03_api_and_runtime_contract.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/03_api_and_runtime_contract.md)

## 서비스 범위

- 비로그인 공개 웹
- 사용자 페이지 `/user`
- 관리자 페이지 `/admin`
- 조회 전용 서비스
- 외부 API + 로컬 마스터 + 서버 추론 구조
- DB는 필요 시 `prediction_logs`만 저장

## 최근 작업 (2026-03-17~20)

### 관리자 페이지 UI 단순화
- [x] 카드형 → 데이터프레임(DataTable) 형식으로 변경
- [x] 위험도 프로그레스 바·배지 제거, 텍스트만 표시
- [x] 컬럼 타이틀 추가 (대여소, 동, 재고, 예측, 차이, 위험, 우선)
- [x] AdminStationRow 제거, DataTable로 통합

### 베타 노출 정책 반영
- [x] 예측 모델 미완성 기간 동안 사용자/관리자 화면 모두 고정 6개 스테이션만 노출
- [x] 사용자 위치 기반 전체 nearby 조회 대신 동일 6개 목록만 반환
- [x] 관리자 위험도 표도 동일 6개 목록만 사용
- [x] 사용자/관리자 스테이션명에 `베타` 표기 추가
- [ ] 베타 6개 선정 기준과 원본 관리 위치를 문서로 확정
- [x] 베타 종료 후 `DDRI_SERVICE_MODE=live`로 전환 가능한 런타임 키 분리

### 우선순위 재조정
- [x] 마스터 데이터 API 자동 갱신은 후순위 작업으로 이동
- [x] 마스터 데이터 DB 저장도 후순위 작업으로 이동
- [x] 현재 DB 최소 스키마(`prediction_logs`)는 유지 가능하다고 판단
- [x] 실시간 재고는 외부 API 기준으로만 사용하고 별도 적재 대상에서 제외
- [x] 미래 시점 재고도 기본 저장 대상이 아니라 예측 계산 결과로 취급
- [ ] 실제 운영 전환 전, `live` 모드용 마스터 로딩 원본과 갱신 절차를 확정

### 에러 처리·보안
- [x] 에러 메시지 사용자용으로 변경 (raw exception 화면 노출 제거)
- [x] 예외·오류 발생 시에도 화면에는 내부 예외 클래스명, stack trace, SQL/쿼리, 파일 경로, 서버/라이브러리 상세 정보 등 공격 단서가 될 수 있는 문자열을 노출하지 않음
- [x] 화면 노출 메시지는 사용자 안내용 일반 문구만 사용하고, 상세 원인은 서버 로그/개발자 콘솔에서만 확인
- [x] FastAPI CORS: `allow_credentials=False` (웹 fetch 호환)
- [x] 인젝션 방지: `fastapi/app/utils/security.py` 입력 검증 적용
  - sort_by, sort_order, district_name, cluster_code, target_datetime 등 화이트리스트·형식 검증
  - 날씨 API 에러 응답에서 traceback 제거

### 보안 노출 정리 작업 (추가 진행)
- [ ] 관리자 예외 스테이션 UI에서 `station_id` 직접 노출 제거
- [ ] 예외 스테이션 영역을 집계형·설명형 문구로 변경 (내부 식별자 비노출)
- [ ] Flutter `ApiException`에서 raw `response.body` 직접 노출되지 않도록 구조 정리
- [ ] 컨트롤러/UI에서 `e.toString()` 또는 서버 응답 원문을 화면에 바인딩하지 않도록 점검
- [ ] FastAPI 4xx 입력 오류 응답 문구를 파라미터명 중심 문구에서 일반 사용자용 안전 문구로 정리
- [ ] 사용자 `/user`, 관리자 `/admin`의 오류·빈 상태·폴백 상태 전체를 화면 비노출 원칙 기준으로 재점검

### 지도 성능
- [x] 고줌 시 앱 멈춤 방지: maxZoom 18→16
- [x] TileLayer: maxNativeZoom 16, keepBuffer 1, panBuffer 0
- [x] tileUpdateTransformer debounce 80ms
- [x] RepaintBoundary로 지도 리페인트 분리

### 사용자 페이지 반응형·UX (2026-03-17)

- [x] 반응형 레이아웃 구현 (12_ddri_responsive_breakpoints_and_layouts.md 기준)
  - 데스크탑 1024px~: 좌측 45% 지도, 우측 55% 리스트 (좌우 분할)
  - 태블릿 900px~: 좌측 40% 지도, 우측 60% 리스트 (가로폭 충분 시 세로여도 좌우분할)
  - 태블릿 600~899px 가로: 좌우 분할
  - 모바일/태블릿세로: 상하 분할 + 전체 스크롤
- [x] 지도 없을 때 플레이스홀더 (빈 공간 유지, "현 위치로 찾기" 버튼)
- [x] 페이지 진입 시 현 위치 자동 로드 (UserPageController onInit)
- [x] 모바일 오버플로우 해결 (SingleChildScrollView로 전체 스크롤)
- [x] 지도 최소 높이 유지 (DesignToken.userMapMinHeight 280px)
- [x] 모바일 날씨 카드 컴팩트화 (140px, 4열)
- [x] 섹션 순서 통일: 검색 → 날씨 → 지도 → 리스트 (모든 구간 동일)

---

## 기획 변경 사항

| 항목 | 기존 | 변경 | 비고 |
|------|------|------|------|
| 태블릿 좌우분할 조건 | 600~1023px + 가로(landscape)만 | 900px 이상이면 세로여도 좌우분할 | 지도 확대, 12_ddri_responsive_breakpoints_and_layouts.md 보완 |
| 모바일 레이아웃 | Column + Expanded (오버플로우) | SingleChildScrollView + 전체 스크롤 | 오버플로우 방지 |
| 지도 없을 때 | SizedBox.shrink() | 플레이스홀더 + 현 위치 자동 로드 | 빈 공간 방지, 진입 시 자동 조회 |
| 지도 높이 | 38% viewport, 200~400px | 42% viewport, 280~450px | DesignToken.userMapMinHeight/MaxHeight |
| 모바일 날씨 | 174px 카드, 3열 | 140px 카드, 4열, compact 모드 | 세로 공간 절약 |
| 섹션 순서 | 모바일에서 지도→날씨 (불일치) | 검색→날씨→지도→리스트 (통일) | 태블릿/모바일 전환 시 일관성 |

---

## 현재 진행 상태

### 1. 문서 체계

- [x] 기준 문서 3개 재정의
- [x] 기존 상세 문서 `legacy/` 이동
- [x] Stitch 관련 문서 `stitch/` 폴더 정리
- [ ] `docs/api/` 문서 최소 체계로 재정리
- [ ] `fastapi/API_GUIDE.md` 현재 구조 기준으로 정리

### 2. Flutter 웹

- [x] `/user`, `/admin` 라우트 구성
- [x] 기본 경로 `/` → `/user` 연결
- [x] 공통 상단 네비게이션 구성
- [x] 공통 `AppScaffold` 구성
- [x] 공통 테마 및 Design Token 적용
- [x] 사용자 페이지 기본 UI 구현
  - [x] 위치/주소/시간 입력 영역
  - [x] 대여소 카드 목록
  - [x] 길찾기 버튼 연결
  - [x] GetX 상태 관리 연결
  - [x] 주간 날씨 UI (UserWeatherSection)
- [x] 선택 시각 상세 날씨 UI
- [x] 베타 고정 6개 리스트 노출
  - [ ] 날짜 선택 범위 현재 시점 ~ 7일 이내 제한
- [x] 관리자 페이지 기본 UI 구현
  - [x] 기준 시간/필터 제어 영역
  - [x] 요약 카드
  - [x] 대여소 표
- [x] 예외 스테이션 섹션
- [x] GetX 상태 관리 연결
- [x] 베타 고정 6개 표 노출
  - [ ] 주간 날씨 UI
  - [ ] 기준 시각 상세 날씨 UI
- [x] 목업 API 클라이언트 연결
- [x] 사용자/관리자 컨트롤러에서 실제 목업 API 호출 연결
- [x] 사용자 페이지 지도 (flutter_map, OSM 타일, 줌/패닝 성능 조정)
- [ ] 실제 백엔드 응답 기준으로 화면 바인딩
- [x] 사용자 페이지 반응형 레이아웃 (모바일/태블릿/데스크탑)
- [ ] 관리자 페이지 반응형 점검

### 3. 화면 정합성

- [x] Stitch export 기준 화면 반영 시작
- [x] 관리자 페이지 주요 구성 정리
- [x] 사용자 페이지 반응형·UX 정합 (검색→날씨→지도→리스트, 지도 최소 높이)
- [ ] 사용자 페이지와 Stitch 기준 정합성 최종 점검
- [ ] 관리자 페이지와 Stitch 기준 정합성 최종 점검
- [ ] 모바일/태블릿/데스크탑 공통 밀도 점검
- [ ] 오류·폴백·빈 상태에서도 화면에 내부 구현 정보나 익셉션 단서가 노출되지 않는지 점검

### 4. FastAPI

- [x] 사용자 조회 API 목업 엔드포인트
- [x] 관리자 조회 API 목업 엔드포인트
- [x] 스테이션/날씨 목업 엔드포인트
- [x] 베타 고정 6개 스테이션 공용 목업 데이터로 통합
- [x] FastAPI 메인 앱에 DDRI 라우터 등록
- [x] CORS 설정 (웹 fetch 호환)
- [x] 입력 검증·인젝션 방지 (security.py)
- [ ] 외부 실시간 재고 API 연동
- [ ] 주간 날씨 + 선택 시각 날씨 응답 구조 확정
- [ ] 예측 모델 런타임 연결
- [ ] 로컬 마스터 로딩 구조 확정
- [ ] 예외/폴백 처리 규칙 구현
- [ ] 입력 오류/예외 응답의 외부 노출 문구 일반화

### 5. 데이터 계층

- [x] 최소 DB 방향 재정의
- [x] ERD / DBML / init schema 최소화
- [ ] `prediction_logs` 실제 저장 여부 결정
  - ML 모델 출력 스키마 확정 후 진행
  - 정의 확정 시 `fastapi/mysql/init_schema.sql`과 ERD 문서 함께 갱신
- [ ] 로컬 마스터 JSON 스키마 확정
- [ ] 마스터 데이터 DB 저장 필요성 재평가
- [ ] 외부 API 응답 -> 내부 모델 입력 변환 규칙 확정
- [ ] 예측 로그 외 저장 대상이 실제로 필요한지 재검토

### 6. 검증

- [ ] Chrome 실환경 실행 검증
- [ ] 사용자 조회 시나리오 점검
- [ ] 관리자 조회 시나리오 점검
- [ ] 외부 API 실패 시 폴백 동작 점검
- [ ] 예외 스테이션 처리 점검
- [ ] 보안 노출 정리 작업 결과 점검 (`station_id`, raw body, 내부 예외 문자열 비노출)

## 바로 다음 작업

1. `docs/api/`와 `fastapi/API_GUIDE.md`를 새 기준 문서 체계에 맞게 정리
2. 보안 노출 정리 작업 수행 (`station_id` 비노출, `ApiException` 정리, 입력 오류 문구 일반화)
3. 베타 6개 스테이션의 선정 기준·원본 설정 위치 문서화
4. 관리자 페이지 주간/기준 시각 날씨 UI (선택)
5. 외부 실시간 재고 API 연동 설계 확정
6. 실제 예측 런타임 연결
7. 마스터 데이터 로딩·갱신·저장 전략 재검토
8. ML 모델 확정 후 `prediction_logs` 스키마와 ERD 갱신

## Live 전환 체크리스트

- [ ] `DDRI_SERVICE_MODE=live` 전환 전 실제 운영 데이터 소스 준비 완료
- [ ] 사용자 nearby API가 고정 6개가 아닌 운영 조회 경로를 사용하도록 교체
- [ ] 관리자 risk API가 운영 계산 경로를 사용하도록 교체
- [ ] 스테이션 마스터 API가 운영 마스터 원본을 사용하도록 교체
- [ ] `베타` 표기와 베타 안내 문구가 운영 모드에서 제거되는지 확인
- [ ] 운영 모드의 예외 처리와 보안 노출 원칙 재점검
- [ ] 마스터 데이터 DB 저장 필요성 최종 판단
- [ ] 운영 전환 후 문서 전체 갱신

## 작업 원칙

- 이 파일은 웹서비스 실행 플랜만 다룬다.
- ML 연구 플랜, 발표 플랜, 리포트 작업은 포함하지 않는다.
- 세부 설명은 기준 문서에서 관리하고, 이 파일은 체크리스트 중심으로 유지한다.
- 예외 상황에서도 UI에는 사용자용 안전 문구만 표시하고, 공격 단서가 될 수 있는 내부 오류 정보는 노출하지 않는다.
