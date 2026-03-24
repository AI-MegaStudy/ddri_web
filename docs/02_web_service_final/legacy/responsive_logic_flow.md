# DDRI 반응형 로직 흐름도

작성일: 2026-03-24  
목적: 현재 앱에 구현된 반응형 로직을 코드 흐름 기준으로 간단히 따라 읽을 수 있게 정리

---

## 1. 먼저 보는 기준값

반응형 기준값은 `lib/core/design_token.dart`에 모여 있다.

| 구간 | 기준 |
|------|------|
| 모바일 | `0 ~ 599px` |
| 태블릿 | `600 ~ 1023px` |
| 데스크탑 | `1024px ~` |
| 사용자 화면 좌우분할 보조 기준 | `900px ~` |
| 관리자 화면 콘텐츠 좌우분할 기준 | `1100px ~` |

---

## 2. 전체 구조 한눈에 보기

```text
[화면 진입]
   |
   v
[AppScaffold]
   |
   +--> [TopNavBar]
   |       |
   |       +--> MediaQuery로 width/height 읽음
   |       +--> 화면 라벨 표시: 모바일 / 태블릿 / 데스크탑
   |
   +--> [페이지 body]
           |
           +--> LayoutBuilder로 현재 width 확인
           +--> 페이지별 분기
                   |
                   +--> UserView
                   |       |
                   |       +--> 좌우 분할인지 판단
                   |       +--> 좌우 분할 or 상하 스택
                   |
                   +--> AdminView
                           |
                           +--> 좌우 분할인지 판단
                           +--> 좌우 분할 or 세로 스택
```

---

## 3. 사용자 화면 흐름

핵심 파일: `lib/view/user_view.dart`

### 3.1 판단 흐름

```text
[UserView build]
   |
   +--> LayoutBuilder에서 width, height 확인
   +--> MediaQuery에서 orientation 확인
   |
   v
[useSideLayout 계산]
   |
   +--> width >= 1024
   |       -> 좌우 분할
   |
   +--> 600 <= width < 1024
   |       |
   |       +--> width >= 900
   |       |       -> 좌우 분할
   |       |
   |       +--> 아니면 landscape 인가?
   |               -> 예: 좌우 분할
   |               -> 아니오: 상하 스택
   |
   +--> width < 600
           -> 상하 스택
```

### 3.2 실제 배치 흐름

```text
[좌우 분할]
   |
   +--> 검색 영역
   +--> 날씨 영역
   +--> 하단 본문을 Row로 분할
           |
           +--> 지도
           +--> 대여소 리스트

[상하 스택]
   |
   +--> 검색 영역
   +--> 날씨 영역
   +--> 지도
   +--> 대여소 리스트
```

### 3.3 사용자 화면에서 같이 반응형 처리되는 컴포넌트

- `user_search_area.dart`
  버튼과 반경 칩을 `Wrap`으로 배치해서 폭이 줄면 자동 줄바꿈
- `user_weather_section.dart`
  내부 너비에 따라 날씨 카드 그리드 크기와 간격 조정
- `user_map_section.dart`
  직접 브레이크포인트를 판단하지는 않고, 부모가 준 높이를 따라감

---

## 4. 관리자 화면 흐름

핵심 파일: `lib/view/admin_view.dart`

### 4.1 판단 흐름

```text
[AdminView build]
   |
   +--> LayoutBuilder에서 width 확인
   |
   v
[useSplitLayout 계산]
   |
   +--> width >= 1100
   |       -> 좌우 분할
   |
   +--> width < 1100
           -> 세로 스택
```

### 4.2 실제 배치 흐름

```text
[공통 상단]
   |
   +--> 제목
   +--> 제어 영역
   +--> 날씨
   +--> 요약 카드
   |
   v
[본문 분기]
   |
   +--> 좌우 분할
   |       |
   |       +--> 왼쪽: 대여소 목록
   |       +--> 오른쪽: 지도 + 예외 항목
   |
   +--> 세로 스택
           |
           +--> 대여소 목록
           +--> 예외 항목
           +--> 지도
```

### 4.3 관리자 화면에서 같이 반응형 처리되는 컴포넌트

- `admin_control_area.dart`
  `900px` 이상이면 한 줄 `Row`, 미만이면 `Wrap + Column`
- `admin_summary_cards.dart`
  `1024px` 이상이면 4열, 미만이면 2열
- `admin_station_list.dart`
  `920px` 미만이면 카드형 목록, 이상이면 테이블형
- `admin_weather_section.dart`
  너비에 따라 7열 / 4열 / 2열 그리드로 조정

---

## 5. 상단 네비게이션 흐름

핵심 파일: `lib/common/layout/top_nav_bar.dart`

```text
[TopNavBar]
   |
   +--> MediaQuery로 width, height 읽음
   +--> width 기준으로 라벨 계산
   |       |
   |       +--> 1024 이상: 데스크탑
   |       +--> 600 이상: 태블릿
   |       +--> 그 외: 모바일
   |
   +--> width >= 480 이면 뷰포트 배지 표시
   +--> width < 720 이면 배지 폭을 더 작게 사용
```

주의:

- 현재 구현은 모바일에서도 상단 메뉴를 햄버거 메뉴로 바꾸지 않는다.
- 즉, 네비게이션은 "완전 다른 모바일 UI"보다는 "같은 구조를 유지하고 일부만 압축"하는 방식이다.

---

## 6. 따라 읽는 순서

반응형 로직을 코드에서 바로 따라가려면 아래 순서로 보면 된다.

1. `lib/core/design_token.dart`
   브레이크포인트 값 확인
2. `lib/common/layout/top_nav_bar.dart`
   공통 상단 바의 화면 크기 처리 확인
3. `lib/view/user_view.dart`
   사용자 페이지의 큰 레이아웃 분기 확인
4. `lib/view/user/user_search_area.dart`
   검색 UI 줄바꿈 방식 확인
5. `lib/view/user/user_weather_section.dart`
   사용자 날씨 그리드 반응형 확인
6. `lib/view/admin_view.dart`
   관리자 페이지의 큰 레이아웃 분기 확인
7. `lib/view/admin/admin_control_area.dart`
   관리자 제어영역 한 줄/줄바꿈 분기 확인
8. `lib/view/admin/admin_station_list.dart`
   카드형/테이블형 전환 확인

---

## 7. 한 줄 요약

현재 DDRI 앱의 반응형은 `DesignToken`의 브레이크포인트를 기준으로, 각 페이지에서 `LayoutBuilder`와 `MediaQuery`로 화면 폭을 읽고 `좌우 분할` 또는 `상하 스택`으로 나누는 구조다.
