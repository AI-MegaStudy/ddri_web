// DDRI 관리자 페이지: 제어, 요약 카드, DataTable, 예외, 맵 플레이스홀더
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
class AdminView extends StatelessWidget {
  const AdminView({super.key});

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
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AdminPageController>()) {
      Get.put(AdminPageController(), permanent: true);
    }

    return AppScaffold(
      title: '재배치 관리',
      currentPath: '/admin',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = _pagePadding(constraints.maxWidth);
          final useSplitLayout = _useSplitContentLayout(constraints.maxWidth);
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
                              style: Theme.of(context).textTheme.headlineMedium
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
                                  ?.copyWith(color: const Color(0xFF64748B)),
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
                        '© 2023 DDRI Reallocation Support System. Gangnam-gu Smart Mobility Division.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminContentSplitLayout extends StatelessWidget {
  const _AdminContentSplitLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(flex: 8, child: AdminStationList()),
        SizedBox(width: DesignToken.adminSectionSpacing),
        const Expanded(flex: 4, child: _DeferredAdminSidePanel()),
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
    final ctrl = Get.find<AdminPageController>();

    return Obx(() {
      if (!ctrl.isSupplementReady.value) {
        return const SizedBox.shrink();
      }
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminWeatherSection(),
          SizedBox(height: DesignToken.adminSectionSpacing),
          AdminSummaryCards(),
        ],
      );
    });
  }
}

class _DeferredAdminSidePanel extends StatelessWidget {
  const _DeferredAdminSidePanel();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminPageController>();

    return Obx(() {
      if (!ctrl.isSupplementReady.value) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(
              '목록을 먼저 표시하는 중입니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

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
              '예외 항목과 지도는 재배치 판단을 보조하는 정보로 유지합니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            SizedBox(height: DesignToken.adminSectionSpacing),
            const AdminExceptionsSection(),
            SizedBox(height: DesignToken.adminSectionSpacing),
            const _DeferredAdminMap(),
          ],
        ),
      );
    });
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
      if (ctrl.isMapReady.value) {
        return const AdminMapPlaceholder();
      }
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(height: 14),
              Text(
                '목록을 먼저 표시한 뒤 지도를 준비 중입니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    });
  }
}
