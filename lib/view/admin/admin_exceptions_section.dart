// DDRI 예외 데이터 안내: 내부 식별자 없이 집계형 문구만 노출
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/design_token.dart';
import '../../vm/admin_page_controller.dart';

/// 예외 데이터 접이식 영역. 내부 station_id는 화면에 노출하지 않는다.
class AdminExceptionsSection extends StatelessWidget {
  const AdminExceptionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminPageController>();

    return Obx(() {
      if (ctrl.exceptions.isEmpty) return const SizedBox.shrink();

      final totalCount = ctrl.exceptions.fold<int>(
        0,
        (sum, item) => sum + item.count,
      );
      final summaryText = ctrl.exceptions
          .map((e) => e.count > 1 ? '${e.reason} ${e.count}건' : e.reason)
          .join(' · ');

      return Container(
        decoration: BoxDecoration(
          color: DesignToken.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DesignToken.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: ctrl.toggleExceptionsExpanded,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '예외 데이터 $totalCount건이 운영 집계에서 제외되었습니다.',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      Icon(
                        ctrl.exceptionsExpanded.value
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.orange.shade700,
                      ),
                    ],
                  ),
                ),
              ),
              if (ctrl.exceptionsExpanded.value)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '$summaryText\n\n'
                      '세부 대여소 식별자는 화면에 노출하지 않으며, 운영 점검이 필요한 항목 수만 안내합니다. '
                      '원인 확인은 서버 로그와 내부 운영 도구에서 진행합니다.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
