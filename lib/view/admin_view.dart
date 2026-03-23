// DDRI 관리자 페이지: 제어, 요약 카드, DataTable, 예외, 맵 플레이스홀더
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app_config.dart';
import '../common/beta/beta_mode_widgets.dart';
import '../common/layout/app_scaffold.dart';
import '../core/design_token.dart';
import 'admin/admin_control_area.dart';
import 'admin/admin_exceptions_section.dart';
import 'admin/admin_map_placeholder.dart';
import 'admin/admin_weather_section.dart';
import '../vm/admin_page_controller.dart';
import 'admin/admin_station_list.dart';
import 'admin/admin_summary_cards.dart';

/// 관리자 페이지: 재배치 판단 목록.
/// 상단 제어/요약 후, 데스크탑에서는 리스트와 지도 패널을 분리해 배치한다.
class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  bool _betaDialogQueued = false;

  /// 화면 너비에 따른 패딩
  EdgeInsets _pagePadding(double width) {
    if (width >= DesignToken.breakpointDesktop) {
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 32);
    }
    if (width >= DesignToken.breakpointTablet) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
  }

  bool _useSplitContentLayout(double width) => width >= 1100;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_betaDialogQueued) return;
    _betaDialogQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !BetaModeNoticeStore.shouldShowToday()) return;
      _showBetaNoticeDialog();
    });
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
                    '현재 관리자 화면은 선별된 6개 대여소 기준으로 제공됩니다. 실제 전체 재배치 판단 대상과 차이가 있을 수 있습니다.',
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
    if (!Get.isRegistered<AdminPageController>()) {
      Get.put(AdminPageController(), permanent: true);
    }

    final ctrl = Get.find<AdminPageController>();

    return Obx(() {
      final isBetaMode = ctrl.isBetaMode;
      return BetaModeRibbon(
        enabled: isBetaMode,
        child: AppScaffold(
          title: AppConfig.adminPageTitle,
          currentPath: '/admin',
          body: LayoutBuilder(
            builder: (context, constraints) {
              final padding = _pagePadding(constraints.maxWidth);
              final useSplitLayout = _useSplitContentLayout(
                constraints.maxWidth,
              );
              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Padding(
                      padding: padding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Obx(() {
                            final ctrl = Get.find<AdminPageController>();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '관리자 - 재배치 판단 지원',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.8,
                                        color: const Color(0xFF0F172A),
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  ctrl.dashboardSubtitle,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xFF64748B),
                                      ),
                                ),
                              ],
                            );
                          }),
                          SizedBox(height: DesignToken.adminSectionSpacing),
                          const AdminControlArea(),
                          SizedBox(height: DesignToken.adminSectionSpacing),
                          const _DeferredAdminSupplement(),
                          SizedBox(height: DesignToken.adminSectionSpacing),
                          useSplitLayout
                              ? const _AdminContentSplitLayout()
                              : const _AdminContentStackLayout(),
                          const SizedBox(height: 24),
                          Text(
                            AppConfig.adminFooterCopy,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF94A3B8)),
                          ),
                        ],
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

class _AdminContentSplitLayout extends StatelessWidget {
  const _AdminContentSplitLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(flex: 5, child: AdminStationList()),
        SizedBox(width: DesignToken.adminSectionSpacing),
        const Expanded(flex: 7, child: _DeferredAdminSidePanel()),
      ],
    );
  }
}

class _AdminContentStackLayout extends StatelessWidget {
  const _AdminContentStackLayout();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminStationList(),
        SizedBox(height: DesignToken.adminSectionSpacing),
        AdminExceptionsSection(),
        SizedBox(height: DesignToken.adminSectionSpacing),
        _DeferredAdminMap(),
      ],
    );
  }
}

class _DeferredAdminSupplement extends StatelessWidget {
  const _DeferredAdminSupplement();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminWeatherSection(),
        SizedBox(height: DesignToken.adminSectionSpacing),
        AdminSummaryCards(),
      ],
    );
  }
}

class _DeferredAdminSidePanel extends StatelessWidget {
  const _DeferredAdminSidePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: DesignToken.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Text(
              '보조 패널',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DesignToken.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '지도는 재배치 판단의 우선 보조 정보로 두고, 예외 항목은 아래에서 보조적으로 확인합니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          SizedBox(height: DesignToken.adminSectionSpacing),
          const _DeferredAdminMap(),
          SizedBox(height: DesignToken.adminSectionSpacing),
          const AdminExceptionsSection(),
        ],
      ),
    );
  }
}

class _DeferredAdminMap extends StatelessWidget {
  const _DeferredAdminMap();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminPageController>();

    return Obx(() {
      if (ctrl.items.isEmpty) {
        return const AdminMapPlaceholder();
      }
      return const AdminMapPlaceholder();
    });
  }
}
