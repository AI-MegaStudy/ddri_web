# DDRI 화면 설계 및 범위

작성일: 2026-03-19  
목적: 현재 웹서비스의 범위, 화면 구성, 반응형 기준, Stitch 참조 문서를 한 곳에서 관리한다.

## 1. 서비스 범위

### 현재 서비스 성격

- 강남구 따릉이 예측 모니터링 웹
- 비로그인 공개 웹
- 사용자 입력형 서비스가 아니라 조회형 서비스
- 사용자 페이지와 관리자 페이지 두 축으로 구성

### 현재 포함 범위

- 사용자 페이지 `/user`
- 관리자 페이지 `/admin`
- 예측 결과 조회
- 실시간 재고 및 운영 상태 조회
- 반응형 웹 대응

### 현재 제외 범위

- 로그인, 회원가입, 권한 관리
- 즐겨찾기, 마이페이지, 사용자 설정
- 이용권, 결제, 구독
- 재배치 실행 기능
- 통계 전용 페이지

## 2. 화면 기준 원칙

- 화면 설계가 API와 시스템 설계보다 우선한다.
- 데스크탑, 태블릿, 모바일은 같은 정보 구조를 유지한다.
- 사용자 페이지는 “대여 가능성 조회”, 관리자 페이지는 “부족 위험 모니터링”에 집중한다.
- 군집은 화면상 핵심 제어값이 아니라 보조 설명값으로 다룬다.
- Stitch 산출물은 최종 UI 기준 레퍼런스로 유지한다.

## 3. 라우트 구성

- `/`
  - 기본 진입은 `/user`와 동일하게 동작
- `/user`
  - 일반 사용자용 조회 페이지
- `/admin`
  - 관리자용 재배치 판단 지원 페이지

## 4. 사용자 페이지

경로: `/user`

### 목적

- 현재 위치 또는 지정 위치 기준으로 주변 대여소를 조회한다.
- 지정 시간 기준 예측 결과와 현재 재고를 함께 보여준다.
- 주간 날씨와 선택 시간대 예상 날씨를 함께 보여준다.

### 주요 섹션

1. 검색/입력 영역
   - 내 위치 찾기
   - 주소 찾기
   - 날짜/시간 선택
   - 조회 방식 선택: `전체보기`, `300m`, `500m`, `1km`
2. 지도 영역
   - 사용자 위치 중심
   - 단일 지도
   - 필요 시 반경 기준 해석 가능
   - 대여소 마커
3. 날씨 영역
   - 일주일치 일별 날씨 요약
   - 선택 날짜/시간 기준 예상 날씨
   - 아이콘, 최고/최저, 날씨 상태 표시
4. 대여소 목록
   - 거리
   - 대여소명
   - 현재 자전거 수
   - 예측 결과
   - 대여 가능 여부
   - 길찾기 버튼
5. 상태 안내
   - 로딩
   - 결과 없음
   - 예외 스테이션
   - 실시간 비노출

### 날씨 UI 원칙

- 기본 상태에서 오늘 포함 7일치 일별 날씨를 보여준다.
- 사용자가 날짜/시간을 선택하면 해당 시각 기준 예상 날씨를 별도 강조한다.
- 주간 날씨는 한 줄 스트립 또는 카드형 리스트로 본다.
- 선택 시간대 날씨는 현재 재고/예측 정보와 같은 문맥에서 본다.
- 과거 날짜 선택은 허용하지 않는다.
- 사용자 날짜 선택 범위는 현재 시점부터 7일 이내로 제한한다.

### Stitch 및 상세 참조

- Stitch export:
  - [user](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/stitch/stitch_export/user)
- Stitch 제작 가이드:
  - [09_stitch_design_application_guide.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/stitch/09_stitch_design_application_guide.md)
- Stitch 진행 메모:
  - [11_stitch_mcp_progress_and_references.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/stitch/11_stitch_mcp_progress_and_references.md)
- 기존 상세 설계:
  - [08_ddri_user_page_spec_detail.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/legacy/08_ddri_user_page_spec_detail.md)
  - [10_ddri_user_page_map_ux_spec.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/legacy/10_ddri_user_page_map_ux_spec.md)

## 5. 관리자 페이지

경로: `/admin`

### 목적

- 특정 시각 기준으로 부족 위험이 큰 대여소를 빠르게 파악한다.
- 재배치 실행이 아니라 판단 지원 정보 제공에 집중한다.
- 같은 화면 안에서 주간 날씨와 기준 시각 예상 날씨를 함께 확인한다.

### 주요 섹션

1. 상단 제어 영역
   - 기준 날짜/시간
   - 긴급 필터
   - 행정동 필터
   - 정렬 기준
2. 날씨 영역
   - 일주일치 일별 날씨 요약
   - 기준 시각 예상 날씨 강조
3. 요약 카드
   - 전체 수
   - 위험 수
   - 예외 수
   - 평균 위험도
4. 메인 목록
   - 대여소명
   - 행정동
   - 현재 재고
   - 예측 수요 또는 예측 결과
   - 재고 차이
   - 위험도
   - 우선순위
5. 예외 영역
   - 실시간 비노출
   - 운영 제외 대상
6. 지도 영역
   - 현재는 보조 영역
   - 추후 확장 가능

### Stitch 및 상세 참조

- Stitch export:
  - [admin](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/stitch/stitch_export/admin)
- Stitch 제작 가이드:
  - [09_stitch_design_application_guide.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/stitch/09_stitch_design_application_guide.md)
- Stitch 진행 메모:
  - [11_stitch_mcp_progress_and_references.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/stitch/11_stitch_mcp_progress_and_references.md)
- 기존 상세 설계:
  - [13_ddri_admin_page_plan.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/legacy/13_ddri_admin_page_plan.md)
  - [admin_layout_behavior.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/legacy/admin_layout_behavior.md)

## 6. 반응형 기준

### 브레이크포인트

- 모바일: `0 ~ 599px`
- 태블릿: `600 ~ 1023px`
- 데스크탑: `1024px ~`

### 공통 원칙

- 색상, 타이포, 컴포넌트는 공통 Design Token 유지
- 정보 구조는 유지하고 레이아웃만 구간별로 달라진다
- 모바일에서는 세로 스택
- 태블릿에서는 wrap 또는 상하 분할
- 데스크탑에서는 좌우 분할과 넓은 표 중심

### 참조 문서

- [12_ddri_responsive_breakpoints_and_layouts.md](/Users/cheng80/Desktop/ddri_web/docs/02_web_service_final/legacy/12_ddri_responsive_breakpoints_and_layouts.md)

## 7. 현재 구현 기준

- 사용자 페이지와 관리자 페이지 모두 실제 API 기준으로 화면이 연결된 상태다.
- 사용자 페이지는 현재 top6 기준으로 `전체보기`, `300m`, `500m`, `1km` 중 하나를 선택해 조회한다.
- `전체보기`는 반경 미적용, `300m`, `500m`, `1km`는 선택 반경 이내 top6만 노출한다.
- 관리자 화면은 Stitch와 최대한 정합성을 맞추는 방향으로 조정 중이다.
- 전체 운영 스테이션 확장은 아직 후속 단계다.

## 8. 이 문서의 우선순위

- 화면 관련 판단은 이 문서를 기준으로 한다.
- Stitch 자료는 이 문서에서 링크한 범위만 현재 기준 참조로 본다.
- 기존 상세 문서와 충돌하면 이 문서를 우선한다.
