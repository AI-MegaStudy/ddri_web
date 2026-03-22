# 08 사용자 모듈 디자인 발표 스피치 보고서

## 1. 발표 개요
- 발표 주제: `06_user_module_design_obx_rx.drawio` 기반 사용자 화면 모듈 구조
- 대상: 개발팀/기획팀/검토자
- 권장 발표 시간: 4~6분
- 발표 목표: 사용자 화면의 상태관리 흐름(`put -> find -> Obx/Rx`)을 빠르게 공유

## 2. 한 줄 핵심 메시지
사용자 화면은 `UserView`에서 컨트롤러를 1회 `put`하고, 하위 위젯들이 `find`로 공유하며, `Obx + Rx`로 화면을 반응형 갱신하는 구조입니다.

## 3. 발표 스크립트 (발표자가 읽는 멘트)
안녕하세요. 사용자 모듈 디자인을 설명드리겠습니다.  
먼저 진입은 `main.dart -> app.dart -> router.dart` 순서이며, `/user` 라우트로 들어오면 `UserView`가 렌더링됩니다.

핵심은 `UserView`에서 `Get.put(UserPageController(), permanent: true)`를 수행한다는 점입니다.  
이렇게 등록된 컨트롤러를 하위 위젯들이 `Get.find<UserPageController>()`로 공유합니다.

하위 모듈을 보면, `user_search_area.dart`는 위치/주소/시간/반경 필터 입력을 받고,  
`fetchCurrentLocation()`, `applyAddressAndFetch(...)`, `onRadiusFilterChanged(...)`, `onDatetimeChanged(...)`를 호출합니다.

`user_weather_section.dart`는 날씨 카드 영역으로, `Obx`에서 `weeklyForecast`, `selectedForecast`, `weatherExpanded` 상태를 구독합니다.  
`toggleWeatherExpanded()`와 `retryWeather()`로 사용자 액션을 처리합니다.

`user_map_section.dart`는 지도 전용 모듈입니다.  
`Obx`로 목록과 포커스 상태를 반영하고, `ever(focusedStation, items)`를 통해 포커스가 바뀔 때 지도 이동을 동기화합니다.

`user_station_list.dart`와 `user_station_card.dart`는 목록 렌더링과 선택 동작을 담당합니다.  
카드 클릭 시 `focusStation(station)`을 호출해 컨트롤러의 선택 상태를 업데이트합니다.

컨트롤러 내부에서는 Rx 상태를 중심으로 화면 상태를 관리합니다.  
좌표, 주소, 목표 시각, 선택 반경, 대여소 목록, 포커스 대여소, 날씨 데이터, 로딩/에러 상태가 모두 Rx로 관리됩니다.

데이터 호출은 `DdriApiClient`를 통해 이루어지며,  
주요 엔드포인트는 `/v1/user/stations/nearby`, `/v1/weather/direct`, `/v1/weather/direct/single`입니다.

정리하면, 사용자 모듈은 입력-조회-표시-선택이 컨트롤러 하나로 일관되게 연결되고,  
`Obx + Rx`로 필요한 화면만 갱신하도록 설계되어 유지보수성이 높은 구조입니다.

## 4. 예상 질문과 답변
Q. 왜 `UserView`에서 컨트롤러를 `permanent: true`로 등록했나요?  
A. 사용자/관리자 페이지 전환 시에도 컨트롤러 생명주기를 안정적으로 유지하고, 재생성 비용과 상태 유실을 줄이기 위함입니다.

Q. 왜 `GetBuilder` 대신 `Obx + Rx`를 사용했나요?  
A. 이 구조는 상태 필드 단위 반응형 갱신이 쉬워서 현재 화면 구성과 잘 맞습니다.

Q. 지도는 왜 별도 동기화 로직이 있나요?  
A. 목록 선택 상태(`focusedStation`)와 지도 포커스를 실시간으로 맞추기 위해 `ever` 기반 반응을 사용합니다.

## 5. 마무리 멘트
사용자 모듈은 컨트롤러 단일 책임과 위젯 분리를 통해 상태 흐름이 명확합니다.  
다음 단계에서는 이 구조를 기준으로 성능 계측과 예외 처리 메시지 표준화를 진행하겠습니다.
