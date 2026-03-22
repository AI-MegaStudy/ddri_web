# 09 관리자 모듈 디자인 발표 스피치 보고서

## 1. 발표 개요
- 발표 주제: `06_admin_module_design_obx_rx.drawio` 기반 관리자 화면 모듈 구조
- 대상: 개발팀/기획팀/운영팀
- 권장 발표 시간: 5~7분
- 발표 목표: 관리자 화면의 필터-리스트-지도-요약 흐름을 `put/find/Obx/Rx` 관점으로 설명

## 2. 한 줄 핵심 메시지
관리자 화면은 `AdminView`에서 `AdminPageController`를 `put`하고, 모든 섹션이 `find`로 공유하여 동일한 Rx 상태를 기준으로 동기화됩니다.

## 3. 발표 스크립트 (발표자가 읽는 멘트)
안녕하세요. 관리자 모듈 디자인을 설명드리겠습니다.  
진입 경로는 동일하게 `main.dart -> app.dart -> router.dart`이며, `/admin`에서 `AdminView`가 시작됩니다.

`AdminView`의 가장 중요한 지점은 `Get.put(AdminPageController(), permanent: true)`입니다.  
이 컨트롤러를 기준으로 제어영역, 목록, 지도, 날씨, 요약, 예외 섹션이 모두 연결됩니다.

컨트롤러에는 필터 상태와 결과 상태가 분리되어 있습니다.  
필터 쪽은 `baseDatetime`, `urgentOnly`, `districtName`, `sortBy`, `sortOrder`이고,  
결과 쪽은 `items`, `exceptions`, `weeklyForecast`, `selectedForecast`, `focusedStation`, `summary`입니다.

`admin_control_area.dart`는 사용자 입력 허브입니다.  
날짜/시간, 긴급 여부, 지역, 정렬 변경 시 각각 `setBaseDatetime(...)`, `setUrgentOnly(...)`,  
`setDistrictName(...)`, `setSortBy(...)`, `setSortOrder(...)`를 호출합니다.

`admin_station_list.dart`는 목록 렌더링 모듈입니다.  
`Obx`로 `items`와 `focusedStation`을 구독하고, 항목 선택 시 `focusStation(station)`을 호출합니다.

`admin_map_placeholder.dart`는 지도 모듈입니다.  
`Obx`와 `ever(focusedStation, items)`를 함께 사용해 목록 선택 상태와 지도 중심점을 동기화합니다.

`admin_weather_section.dart`, `admin_summary_cards.dart`, `admin_exceptions_section.dart`는  
각각 날씨, 요약 수치, 예외 항목을 담당하며 같은 컨트롤러 상태를 구독합니다.

데이터 갱신의 중심 함수는 `fetchRiskStations()`입니다.  
컨트롤러 `onReady()`에서 초기 1회 호출되고, 필터 변경 시 재호출되어 화면 전체가 같은 기준으로 갱신됩니다.

정리하면, 관리자 모듈은 하나의 컨트롤러 상태를 여러 섹션이 공유하는 구조라  
필터를 변경했을 때 리스트/지도/요약이 같은 데이터 스냅샷으로 움직이는 것이 핵심입니다.

## 4. 예상 질문과 답변
Q. 왜 섹션별 컨트롤러로 나누지 않았나요?  
A. 관리자 화면은 필터 기준의 동시 갱신이 중요해서 단일 컨트롤러가 일관성 유지에 유리합니다.

Q. 섹션이 많아지면 성능 문제가 생기지 않나요?  
A. `Obx` 구독 단위를 분리해 필요한 섹션만 다시 그리도록 구성했기 때문에 확장 시에도 관리가 가능합니다.

Q. 정렬/필터 유효성은 어디서 보장하나요?  
A. 프론트에서 제어하고, 서버에서도 화이트리스트 검증을 수행하도록 설계되어 있습니다.

## 5. 마무리 멘트
관리자 모듈은 운영 의사결정 화면에 맞게 단일 상태원본을 유지하는 구조입니다.  
다음 단계에서는 필터 프리셋, 로딩 피드백, 장애 대응 메시지를 운영 중심으로 강화하겠습니다.
