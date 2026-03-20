// DDRI 사용자 페이지: 검색, 날씨, 지도, 대여소 목록, 반응형 패딩
// 12_ddri_responsive_breakpoints_and_layouts.md 기준
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../common/layout/app_scaffold.dart';
import '../core/design_token.dart';
import '../vm/user_page_controller.dart';
import 'user/user_map_section.dart';
import 'user/user_search_area.dart';
import 'user/user_station_list.dart';
import 'user/user_weather_section.dart';

/// 사용자 페이지: 근처 대여소 조회.
/// 반응형: 모바일/태블릿세로=상하분할, 데스크탑/태블릿가로=좌우분할.
class UserView extends StatelessWidget {
  const UserView({super.key});

  /// 화면 너비에 따른 패딩 (데스크탑 40/24, 태블릿 24/20, 모바일 0)
  EdgeInsets _pagePadding(double width) {
    if (width >= DesignToken.breakpointDesktop) {
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
    }
    if (width >= DesignToken.breakpointTablet) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 0, vertical: 0);
  }

  /// 좌우 분할 사용 여부.
  /// 데스크탑 1024+ / 태블릿 900+ (가로폭 충분 시 세로여도 좌우분할) / 태블릿 600~899 가로
  bool _useSideLayout(double width, Orientation orientation) {
    if (width >= DesignToken.breakpointDesktop) return true;
    if (width >= DesignToken.breakpointTablet &&
        width < DesignToken.breakpointDesktop) {
      // 900px 이상이면 가로폭 충분 → 좌우분할 (지도 확대)
      if (width >= DesignToken.breakpointTabletSideLayout) return true;
      return orientation == Orientation.landscape;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UserPageController>()) {
      Get.put(UserPageController(), permanent: true);
    }

    return AppScaffold(
      title: '대여소 조회',
      currentPath: '/user',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = _pagePadding(constraints.maxWidth);
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final orientation = MediaQuery.orientationOf(context);
          final useSideLayout = _useSideLayout(width, orientation);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: padding,
                child: useSideLayout
                    ? _AdaptiveSideLayout(width: width, viewportHeight: height)
                    : _ScrollableStackLayout(
                        viewportHeight: constraints.maxHeight,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdaptiveSideLayout extends StatelessWidget {
  const _AdaptiveSideLayout({
    required this.width,
    required this.viewportHeight,
  });

  final double width;
  final double viewportHeight;

  static const double _minFixedHeightForPinnedLayout = 860;
  static const double _minScrollableSidePanelHeight = 360;

  @override
  Widget build(BuildContext context) {
    if (viewportHeight >= _minFixedHeightForPinnedLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UserSearchArea(),
          const UserWeatherSection(),
          Expanded(child: _SideLayout(width: width)),
        ],
      );
    }

    final sidePanelHeight = (viewportHeight * 0.58).clamp(
      _minScrollableSidePanelHeight,
      640.0,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UserSearchArea(),
          const UserWeatherSection(),
          SizedBox(
            height: sidePanelHeight,
            child: _SideLayout(width: width),
          ),
        ],
      ),
    );
  }
}

/// 좌우 분할: 데스크탑 45/55, 태블릿가로 40/60
class _SideLayout extends StatelessWidget {
  const _SideLayout({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final isDesktop = width >= DesignToken.breakpointDesktop;
    final mapFlex = isDesktop ? 45 : 40;
    final listFlex = isDesktop ? 55 : 60;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: mapFlex, child: const UserMapSection()),
        const VerticalDivider(width: 1),
        Expanded(
          flex: listFlex,
          child: const UserStationList(sideLayout: true),
        ),
      ],
    );
  }
}

/// 상하 분할 + 스크롤: 모바일/태블릿세로에서 검색·날씨·지도·리스트 모두 스크롤 (오버플로우 방지)
class _ScrollableStackLayout extends StatelessWidget {
  const _ScrollableStackLayout({required this.viewportHeight});

  final double viewportHeight;

  @override
  Widget build(BuildContext context) {
    final mapHeight = (viewportHeight * 0.42).clamp(
      DesignToken.userMapMinHeight,
      DesignToken.userMapMaxHeight,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UserSearchArea(),
          const UserWeatherSection(),
          SizedBox(height: mapHeight, child: const UserMapSection()),
          const Divider(height: 1),
          const UserStationList(sideLayout: false),
        ],
      ),
    );
  }
}
