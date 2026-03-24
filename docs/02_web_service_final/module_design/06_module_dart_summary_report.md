# DDRI Web Module Dart 파일 연결 요약 보고서

## 1. 문서 목적

본 문서는 아래 두 설계 문서에 등장하는 `dart` 파일들의 역할과 연결 구조를 빠르게 파악할 수 있도록 정리한 요약본이다.

- `06_admin_module_design_obx_rx.drawio`
- `06_user_module_design_obx_rx.drawio`

정리 기준은 다음과 같다.

- 1차 기준: `drawio` 설계도에 표현된 모듈 연결
- 2차 기준: 현재 `lib/` 실제 코드 구조 확인 결과

---

## 2. 전체 구조 한눈에 보기

### 공통 아키텍처 패턴

두 화면 모두 공통적으로 아래 흐름을 따른다.

`main.dart` -> `app.dart` -> `router.dart` -> 각 View 진입 -> `Get.put(Controller)` 등록 -> 하위 위젯들이 `Get.find(Controller)`로 상태 공유

즉, **페이지 단위 View가 Controller를 생성하고**, **하위 섹션 위젯들은 동일 Controller의 Rx 상태를 구독하는 구조**이다.

### 상태 관리 방식

- 상태관리: `GetX`
- 반응형 갱신: `Obx`
- 공유 상태: `Rx`, `RxList`, `RxBool`, `RxString` 등
- 컨트롤러 접근 방식:
  - 상위 View: `Get.put(...)`
  - 하위 섹션/컴포넌트: `Get.find(...)`

---

## 3. Admin 모듈 요약

### 3-1. 연결 구조

`main.dart` + `app.dart` + `router.dart`
-> `/admin` 라우팅
-> `admin_view.dart`
-> `Get.put(AdminPageController)`
-> 아래 하위 위젯들이 `Get.find(AdminPageController)`로 연결

- `admin_control_area.dart`
- `admin_station_list.dart`
- `admin_map_placeholder.dart`
- `admin_weather_section.dart`
- `admin_summary_cards.dart`
- `admin_exceptions_section.dart`

### 3-2. 파일별 역할

#### `main.dart`

- 앱 실행 진입점
- 웹에서 `usePathUrlStrategy()` 적용
- `App()` 실행

#### `app.dart`

- 앱 루트 위젯
- `GetMaterialApp` 설정
- 로케일, 테마, 초기 라우트, `getPages` 설정

#### `router.dart`

- GetX 라우팅 목록 정의
- `/`, `/user`, `/admin` 경로를 각각 페이지에 연결
- `/admin` 경로에서 `AdminView`로 진입

#### `admin_view.dart`

- 관리자 화면의 최상위 View
- 진입 시 `AdminPageController`를 `permanent: true`로 등록
- 화면 전체 레이아웃을 조립하는 컨테이너 역할
- 주요 하위 구성:
  - 제어 영역
  - 요약 카드
  - 예외 섹션
  - 목록 영역
  - 지도 영역
  - 날씨 영역

#### `admin_page_controller.dart`

- 관리자 화면의 핵심 상태/비즈니스 로직 담당
- 사실상 Admin 모듈의 중심 허브
- 주요 Rx 상태:
  - 검색/필터: `baseDatetime`, `urgentOnly`, `districtName`, `sortBy`, `sortOrder`
  - 결과 데이터: `items`, `exceptions`, `weeklyForecast`, `selectedForecast`, `summary`
  - 선택 상태: `focusedStation`
  - UI 상태: `isLoading`, `weatherExpanded`, `exceptionsExpanded`, `errorMessage`
- 주요 기능:
  - `onReady()`에서 `fetchRiskStations()` 자동 호출
  - 필터 변경 시 목록 재조회
  - 선택 대여소 변경
  - 예외/날씨 섹션 펼침 상태 변경

#### `admin_control_area.dart`

- 관리자 검색/필터 UI
- 날짜/시간, 긴급 여부, 행정동, 정렬 기준, 정렬 순서를 변경
- 사용자 입력을 Controller 메서드에 전달하는 입력 패널 역할
- 호출 메서드 예:
  - `setBaseDatetime`
  - `setUrgentOnly`
  - `setDistrictName`
  - `setSortBy`
  - `setSortOrder`

#### `admin_station_list.dart`

- 위험 대여소 목록 표시 영역
- `items`, `isLoading`, `focusedStation` 상태를 반영
- 목록/테이블 형태로 데이터를 보여줌
- 항목 선택 시 `focusStation()` 호출

#### `admin_map_placeholder.dart`

- 관리자 지도 표시 영역
- `items`와 `focusedStation`을 기반으로 지도 중심/마커를 갱신
- `ever(...)`로 Controller 상태 변화를 감지해 지도 이동 처리
- 목록에서 선택된 대여소와 지도 포커스를 연결

#### `admin_weather_section.dart`

- 관리자용 날씨 정보 섹션
- `weeklyForecast`, `selectedForecast`, `weatherExpanded`를 사용
- 날씨 패널 펼침/접기 담당

#### `admin_summary_cards.dart`

- 관리자 대시보드 요약 카드 영역
- `summary` 데이터를 시각적으로 표시
- 전체 수, 위험 수, 예외 수 등 핵심 지표 요약

#### `admin_exceptions_section.dart`

- 예외 데이터 안내 영역
- `exceptions`, `exceptionsExpanded`를 사용
- 집계 제외/예외 사유를 접기/펼치기 형태로 노출

### 3-3. Admin 모듈 핵심 연결 해석

- `admin_view.dart`가 `AdminPageController`를 생성한다.
- 나머지 Admin 하위 파일들은 직접 데이터를 들고 있지 않고, 모두 `Get.find(AdminPageController)`로 같은 상태를 바라본다.
- 따라서 Admin 구조는 **"하나의 컨트롤러 + 여러 표시용 섹션 위젯"** 형태다.
- 데이터 흐름은 아래와 같다.

`admin_control_area.dart`
-> 필터 변경
-> `admin_page_controller.dart`
-> `fetchRiskStations()`
-> `items/summary/exceptions/weather` 갱신
-> `admin_station_list.dart`, `admin_map_placeholder.dart`, `admin_summary_cards.dart`, `admin_exceptions_section.dart`, `admin_weather_section.dart` 동시 반응

---

## 4. User 모듈 요약

### 4-1. 연결 구조

`main.dart` + `app.dart` + `router.dart`
-> `/user` 라우팅
-> `user_view.dart`
-> `Get.put(UserPageController)`
-> 아래 하위 위젯들이 `Get.find(UserPageController)`로 연결

- `user_search_area.dart`
- `user_weather_section.dart`
- `user_map_section.dart`
- `user_station_list.dart`
- `user_station_card.dart`

### 4-2. 파일별 역할

#### `user_view.dart`

- 사용자 화면의 최상위 View
- 진입 시 `UserPageController`를 `permanent: true`로 등록
- 검색, 날씨, 지도, 대여소 목록 레이아웃을 조립
- 반응형 레이아웃 분기까지 담당

#### `user_page_controller.dart`

- 사용자 화면의 핵심 상태/비즈니스 로직 담당
- User 모듈의 중심 허브
- 주요 Rx 상태:
  - 위치/검색 조건: `lat`, `lng`, `address`, `targetDatetime`, `selectedRadiusM`
  - 결과 데이터: `items`, `weeklyForecast`, `selectedForecast`
  - 선택 상태: `focusedStation`
  - UI 상태: `isLoading`, `isLoadingLocation`, `isLoadingWeather`, `weatherExpanded`
  - 오류 상태: `errorMessage`, `weatherErrorMessage`
- 주요 기능:
  - 현재 위치 조회
  - 주소 검색 결과 반영
  - 근처 대여소 조회
  - 날씨 조회
  - 반경/시간 변경 시 재조회
  - 선택 대여소 포커싱

#### `user_search_area.dart`

- 사용자 검색 입력 패널
- 현재 위치 찾기, 주소 검색, 날짜/시간 선택, 반경 선택 기능 제공
- Controller 호출 메서드 예:
  - `fetchCurrentLocation()`
  - `applyAddressAndFetch(...)`
  - `onRadiusFilterChanged(...)`
  - `onDatetimeChanged(...)`

#### `user_weather_section.dart`

- 사용자용 날씨 섹션
- 위치가 있을 때만 표시
- `weeklyForecast`, `selectedForecast`, `weatherExpanded`, `weatherErrorMessage` 반영
- 재시도 버튼과 펼침/접기 기능 포함

#### `user_map_section.dart`

- 사용자 지도 영역
- 현재 위치와 근처 대여소를 지도에 표시
- `focusedStation`이 바뀌면 해당 위치로 지도 이동
- 지도 초기화, 확대/축소 등 인터랙션 담당

#### `user_station_list.dart`

- 근처 대여소 목록 표시 영역
- `items`, `isLoading`, `hasLocation`, `stationListTitle` 반영
- 리스트 렌더링 담당
- 실제 각 항목 렌더링은 `user_station_card.dart`에 위임

#### `user_station_card.dart`

- 대여소 개별 카드 컴포넌트
- `StationNearbyItem` 한 건을 표시
- 클릭 시 `focusStation(station)` 호출
- 현재 선택된 대여소인지 여부를 `focusedStation`과 비교해 강조 표시

### 4-3. User 모듈 핵심 연결 해석

- `user_view.dart`가 `UserPageController`를 생성한다.
- `user_search_area.dart`가 검색 조건을 바꾸면 Controller가 API를 다시 호출한다.
- 그 결과로 `items`, `weeklyForecast`, `selectedForecast`, `focusedStation` 등이 바뀌고,
  다음 위젯들이 동시에 다시 그려진다.
  - `user_weather_section.dart`
  - `user_map_section.dart`
  - `user_station_list.dart`
  - `user_station_card.dart`

데이터 흐름은 아래와 같다.

`user_search_area.dart`
-> 위치/주소/반경/시간 변경
-> `user_page_controller.dart`
-> `_fetchStations()` + `_fetchWeather()`
-> `items/weather/focusedStation` 갱신
-> 지도/날씨/목록 카드가 동시 반응

또한 목록 카드 클릭 시:

`user_station_card.dart`
-> `focusStation()`
-> `user_page_controller.dart`
-> `user_map_section.dart`가 선택 대여소로 이동

---

## 5. Admin / User 비교 요약

### 공통점

- 둘 다 `GetX + Obx + Rx` 기반
- 상위 View가 Controller를 생성
- 하위 위젯은 `Get.find()`로 같은 Controller를 공유
- Controller가 API 호출과 상태 변경의 중심
- 지도/목록/날씨 등 복수 위젯이 한 Controller 상태에 동시에 반응

### 차이점

- Admin 모듈은 "위험 대여소 관리/모니터링" 중심
- User 모듈은 "현재 위치 기반 근처 대여소 조회" 중심
- Admin은 요약 카드, 예외 정보, 정렬/행정동 필터가 강조됨
- User는 위치 조회, 주소 검색, 반경 선택, 선택 대여소 포커싱이 강조됨

---

## 6. 실제 코드 확인 시 참고사항

설계도와 실제 코드 비교 시 아래 차이가 확인된다.

- 설계도에는 `AdminView`, `UserView`가 `StatelessWidget`처럼 표현되어 있지만 실제 코드에서는 둘 다 `StatefulWidget`이다.
- User 다이어그램에는 `main.dart`만 직접 보이지만, 실제 앱 진입 구조는 `main.dart -> app.dart -> router.dart -> user/admin view` 형태다.
- Admin 다이어그램의 `main_box`에는 `app.dart + router.dart`가 함께 묶여 있고, 실제 코드도 동일한 책임 분리를 따른다.

즉, **전체 설계 방향은 유지되고 있으며, 실제 구현에서 반응형 레이아웃과 부가 UI 제어를 위해 일부 View가 Stateful로 확장된 상태**로 보면 된다.

---

## 7. 최종 한줄 정리

이 프로젝트의 두 화면은 모두 **"페이지(View)가 GetX Controller를 생성하고, 하위 `dart` 파일들이 그 Controller의 Rx 상태를 공유해서 함께 반응하는 구조"**로 설계되어 있다.
