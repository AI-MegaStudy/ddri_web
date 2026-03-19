// DDRI 관리자 페이지: 제어, 요약 카드, DataTable, 예외, 맵 플레이스홀더
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../common/layout/app_scaffold.dart';
import '../core/design_token.dart';
import 'admin/admin_control_area.dart';
import 'admin/admin_exceptions_section.dart';
import 'admin/admin_map_placeholder.dart';
import '../vm/admin_page_controller.dart';
import 'admin/admin_station_list.dart';
import 'admin/admin_summary_cards.dart';

/// 관리자 페이지: 재배치 판단 목록.
/// AdminControlArea → AdminSummaryCards → AdminStationList → AdminExceptionsSection → AdminMapPlaceholder.
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
                      const AdminSummaryCards(),
                      SizedBox(height: DesignToken.adminSectionSpacing),
                      const AdminStationList(),
                      SizedBox(height: DesignToken.adminSectionSpacing),
                      const AdminExceptionsSection(),
                      SizedBox(height: DesignToken.adminSectionSpacing),
                      const AdminMapPlaceholder(),
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
