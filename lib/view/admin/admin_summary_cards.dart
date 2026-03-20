// DDRI 관리자 요약 카드: 전체/위험/예외/평균 위험도, 반응형 그리드
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/design_token.dart';
import '../../vm/admin_page_controller.dart';

/// 관리자 요약 카드 4개 (전체, 위험, 예외, 평균 위험도).
class AdminSummaryCards extends StatelessWidget {
  const AdminSummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminPageController>();

    return Obx(() {
      final s = ctrl.summary.value;
      if (s == null) return const SizedBox.shrink();

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final cards = [
            _SummaryCard(
              label: '전체',
              value: '${s.totalCount}',
              color: DesignToken.primary,
              icon: Icons.directions_bike,
            ),
            _SummaryCard(
              label: '위험(예상 잔여 5대 이하)',
              value: '${s.riskCount}',
              color: Colors.red.shade600,
              icon: Icons.warning_amber_rounded,
              borderColor: Colors.red.withValues(alpha: 0.14),
            ),
            _SummaryCard(
              label: '예외',
              value: '${s.exceptionCount}',
              color: Colors.orange.shade500,
              icon: Icons.visibility_off,
            ),
            _SummaryCard(
              label: '평균 예상 잔여',
              value: '${s.avgPredictedRemainingBikes.toStringAsFixed(1)}대',
              color: DesignToken.primary,
              icon: Icons.analytics_outlined,
            ),
          ];
          final crossAxisCount = width >= 1024 ? 4 : 2;
          final mainAxisExtent = width >= 1024
              ? 132.0
              : width >= 640
              ? 118.0
              : 104.0;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: mainAxisExtent,
            ),
            itemBuilder: (context, index) => cards[index],
          );
        },
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.borderColor,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? DesignToken.primary.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: label == '위험' ? color : const Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Icon(icon, size: 22, color: color.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}
