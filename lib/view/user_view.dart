// DDRI 사용자 페이지: 검색, 날씨, 지도, 대여소 목록, 반응형 패딩
// 12_ddri_responsive_breakpoints_and_layouts.md 기준
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app_config.dart';
import '../common/beta/beta_mode_widgets.dart';
import '../common/layout/app_scaffold.dart';
import '../core/design_token.dart';
import '../vm/user_page_controller.dart';
import 'user/user_map_section.dart';
import 'user/user_search_area.dart';
import 'user/user_station_list.dart';
import 'user/user_weather_section.dart';

/// 사용자 페이지: 근처 대여소 조회.
/// 반응형: 모바일/태블릿세로=상하분할, 데스크탑/태블릿가로=좌우분할.
class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  bool _betaDialogQueued = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_betaDialogQueued) return;
    _betaDialogQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !BetaModeNoticeStore.shouldShowToday()) return;
      _showBetaNoticeDialogWhenReady();
    });
  }

  Future<void> _showBetaNoticeDialogWhenReady() async {
    if (!mounted) return;

    if (!Get.isRegistered<UserPageController>()) {
      Get.put(UserPageController(), permanent: true);
    }

    final ctrl = Get.find<UserPageController>();
    if (ctrl.isLoadingLocation.value) {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        _showBetaNoticeDialogWhenReady();
      });
      return;
    }

    await _showBetaNoticeDialog();
  }

  Future<void> _showBetaNoticeDialog() async {
    var dontShowToday = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: BetaModePalette.chipBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.campaign_outlined,
                      color: BetaModePalette.chipText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '베타 운영 안내',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: BetaModePalette.dialogAccent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '현재 화면은 선별된 6개 대여소 기준으로 제공됩니다. 실제 전체 대여소 현황과 차이가 있을 수 있습니다.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: dontShowToday,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: BetaModePalette.chipText,
                    title: Text(
                      '오늘은 다시 보지 않기',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        dontShowToday = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('닫기'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: BetaModePalette.chipText,
                  ),
                  onPressed: () async {
                    if (dontShowToday) {
                      await BetaModeNoticeStore.hideForToday();
                    }
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UserPageController>()) {
      Get.put(UserPageController(), permanent: true);
    }

    final ctrl = Get.find<UserPageController>();

    return Obx(() {
      final isBetaMode = ctrl.isBetaMode;
      return BetaModeRibbon(
        enabled: isBetaMode,
        child: AppScaffold(
          title: AppConfig.userPageTitle,
          currentPath: '/user',
          body: LayoutBuilder(
            builder: (context, constraints) {
              final padding = _pagePadding(constraints.maxWidth);
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final orientation = MediaQuery.orientationOf(context);
              final useSideLayout = _useSideLayout(width, orientation);

              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 1280,
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: padding,
                      child: useSideLayout
                          ? _AdaptiveSideLayout(
                              width: width,
                              viewportHeight: height,
                            )
                          : _ScrollableStackLayout(
                              viewportHeight: constraints.maxHeight,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

class _AdaptiveSideLayout extends StatelessWidget {
  const _AdaptiveSideLayout({
    required this.width,
    required this.viewportHeight,
  });

  final double width;
  final double viewportHeight;

  static const double _minSidePanelHeight = 420;
  static const double _maxSidePanelHeight = 760;

  @override
  Widget build(BuildContext context) {
    final sidePanelHeight = (viewportHeight * 0.62).clamp(
      _minSidePanelHeight,
      _maxSidePanelHeight,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const UserSearchArea(),
        const UserWeatherSection(),
        SizedBox(
          height: sidePanelHeight,
          child: _SideLayout(width: width),
        ),
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const UserSearchArea(),
        const UserWeatherSection(),
        SizedBox(height: mapHeight, child: const UserMapSection()),
        const Divider(height: 1),
        const UserStationList(sideLayout: false),
      ],
    );
  }
}
